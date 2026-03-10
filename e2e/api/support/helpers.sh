#!/usr/bin/env bash
# Shared test helpers: curl wrappers, assertions, colored output

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
PASS_COUNT=0
FAIL_COUNT=0

# ── API call logger ─────────────────────────────────────────────────────────────
# Set API_LOG_FILE before sourcing to enable logging (done in the run script).

_log_api_call() {
  [ -z "$API_LOG_FILE" ] && return
  local method="$1"
  local url="$2"
  local payload="$3"  # empty for GET/DELETE
  {
    echo "## $method $url"
    echo ""
    echo "**Status:** $RESPONSE_STATUS"
    echo ""
    if [ -n "$payload" ]; then
      echo "**Request Body:**"
      echo '```json'
      echo "$payload" | jq . 2>/dev/null || echo "$payload"
      echo '```'
      echo ""
    fi
    echo "**Response:**"
    local pretty_body
    if pretty_body=$(echo "$RESPONSE_BODY" | jq . 2>/dev/null); then
      echo '```json'
      echo "$pretty_body"
      echo '```'
    else
      echo '> [non-JSON response]'
    fi
    echo ""
    echo "---"
    echo ""
  } >> "$API_LOG_FILE"
}

# ── curl wrappers ──────────────────────────────────────────────────────────────
# Each wrapper sets:
#   RESPONSE_BODY  — the JSON (or empty) body
#   RESPONSE_STATUS — the HTTP status code
#
# Optional: pass a custom Authorization header as $3 (for api_get/api_delete)
#           or $4 (for api_post/api_put/api_patch).
#           Use "none" to send no Authorization header at all.

_curl_auth_header() {
  local override="$1"
  if [ "$override" = "none" ]; then
    echo ""
  elif [ -n "$override" ]; then
    echo "Authorization: Bearer $override"
  else
    echo "Authorization: Bearer $TOKEN"
  fi
}

api_get() {
  local url="$1"
  local auth_override="$2"
  local auth_header
  auth_header=$(_curl_auth_header "$auth_override")
  local tmp
  tmp=$(mktemp)
  local auth_args=()
  [ -n "$auth_header" ] && auth_args=(-H "$auth_header")
  RESPONSE_STATUS=$(curl -s -o "$tmp" -w '%{http_code}' \
    "${auth_args[@]}" \
    -H "Accept: application/json" \
    "$BASE_URL$url")
  RESPONSE_BODY=$(cat "$tmp")
  rm -f "$tmp"
  _log_api_call "GET" "$url"
}

api_post() {
  local url="$1"
  local data="$2"
  : "${data:="{}"}"
  local auth_override="$3"
  local auth_header
  auth_header=$(_curl_auth_header "$auth_override")
  local tmp
  tmp=$(mktemp)
  local auth_args=()
  [ -n "$auth_header" ] && auth_args=(-H "$auth_header")
  RESPONSE_STATUS=$(curl -s -o "$tmp" -w '%{http_code}' \
    -X POST \
    "${auth_args[@]}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$data" \
    "$BASE_URL$url")
  RESPONSE_BODY=$(cat "$tmp")
  rm -f "$tmp"
  _log_api_call "POST" "$url" "$data"
}

api_put() {
  local url="$1"
  local data="$2"
  : "${data:="{}"}"
  local auth_override="$3"
  local auth_header
  auth_header=$(_curl_auth_header "$auth_override")
  local tmp
  tmp=$(mktemp)
  local auth_args=()
  [ -n "$auth_header" ] && auth_args=(-H "$auth_header")
  RESPONSE_STATUS=$(curl -s -o "$tmp" -w '%{http_code}' \
    -X PUT \
    "${auth_args[@]}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$data" \
    "$BASE_URL$url")
  RESPONSE_BODY=$(cat "$tmp")
  rm -f "$tmp"
  _log_api_call "PUT" "$url" "$data"
}

api_patch() {
  local url="$1"
  local data="$2"
  : "${data:="{}"}"
  local auth_override="$3"
  local auth_header
  auth_header=$(_curl_auth_header "$auth_override")
  local tmp
  tmp=$(mktemp)
  local auth_args=()
  [ -n "$auth_header" ] && auth_args=(-H "$auth_header")
  RESPONSE_STATUS=$(curl -s -o "$tmp" -w '%{http_code}' \
    -X PATCH \
    "${auth_args[@]}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$data" \
    "$BASE_URL$url")
  RESPONSE_BODY=$(cat "$tmp")
  rm -f "$tmp"
  _log_api_call "PATCH" "$url" "$data"
}

api_delete() {
  local url="$1"
  local auth_override="$2"
  local auth_header
  auth_header=$(_curl_auth_header "$auth_override")
  local tmp
  tmp=$(mktemp)
  local auth_args=()
  [ -n "$auth_header" ] && auth_args=(-H "$auth_header")
  RESPONSE_STATUS=$(curl -s -o "$tmp" -w '%{http_code}' \
    -X DELETE \
    "${auth_args[@]}" \
    -H "Accept: application/json" \
    "$BASE_URL$url")
  RESPONSE_BODY=$(cat "$tmp")
  rm -f "$tmp"
  _log_api_call "DELETE" "$url"
}

# ── assertions ─────────────────────────────────────────────────────────────────

assert_status() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if [ "$expected" = "$actual" ]; then
    echo -e "  ${GREEN}PASS${NC} $label (status $actual)"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}FAIL${NC} $label — expected status $expected, got $actual"
    echo -e "       ${YELLOW}Body:${NC} $(echo "$RESPONSE_BODY" | head -c 200)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_json_field() {
  local json="$1"
  local jq_expr="$2"
  local expected="$3"
  local label="$4"
  local actual
  actual=$(echo "$json" | jq -r "$jq_expr" 2>/dev/null)
  if [ "$actual" = "$expected" ]; then
    echo -e "  ${GREEN}PASS${NC} $label ($jq_expr == \"$expected\")"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}FAIL${NC} $label — $jq_expr expected \"$expected\", got \"$actual\""
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_json_not_null() {
  local json="$1"
  local jq_expr="$2"
  local label="$3"
  local actual
  actual=$(echo "$json" | jq -r "$jq_expr" 2>/dev/null)
  if [ -n "$actual" ] && [ "$actual" != "null" ]; then
    echo -e "  ${GREEN}PASS${NC} $label ($jq_expr is present)"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}FAIL${NC} $label — $jq_expr is null or missing"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_json_null() {
  local json="$1"
  local jq_expr="$2"
  local label="$3"
  local actual
  actual=$(echo "$json" | jq -r "$jq_expr" 2>/dev/null)
  if [ "$actual" = "null" ] || [ -z "$actual" ]; then
    echo -e "  ${GREEN}PASS${NC} $label ($jq_expr is null)"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}FAIL${NC} $label — $jq_expr expected null, got \"$actual\""
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# Assert standard success response envelope: {status: "success", type: "...", data: ...}
assert_success_envelope() {
  local json="$1"
  local expected_type="$2"  # "object" or "array"
  local label="$3"
  assert_json_field "$json" ".status" "success" "$label — status"
  assert_json_field "$json" ".type" "$expected_type" "$label — type"
}

# Assert standard failure response envelope: {status: "failure", type: "object", data: {message: "..."}}
assert_failure_envelope() {
  local json="$1"
  local label="$2"
  assert_json_field "$json" ".status" "failure" "$label — failure status"
  assert_json_field "$json" ".type" "object" "$label — failure type"
  assert_json_not_null "$json" ".data.message" "$label — failure message"
}

# ── section header ─────────────────────────────────────────────────────────────

section() {
  echo ""
  echo -e "${CYAN}━━━ $1 ━━━${NC}"
}

# ── summary ────────────────────────────────────────────────────────────────────

print_summary() {
  local total=$((PASS_COUNT + FAIL_COUNT))
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  Total: $total  ${GREEN}Passed: $PASS_COUNT${NC}  ${RED}Failed: $FAIL_COUNT${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  if [ "$FAIL_COUNT" -gt 0 ]; then
    return 1
  fi
}
