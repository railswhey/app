#!/usr/bin/env bash
# Test: Task List Transfers — full flow with two users
# Docs: POST /task_lists/:list_id/transfer.json  (request transfer)
#       GET  /transfers/:token.json               (show transfer)
#       PATCH /transfers/:token.json              (accept/reject)
#
# Requires: TOKEN_A, TOKEN_B, USER_B_EMAIL (set by e2e/api/run)

section "Transfers"

SAVED_TOKEN="$TOKEN"

# ── SETUP: User A creates a list to transfer ─────────────────────────────────

TOKEN="$TOKEN_A"

api_post "$(task_lists_path)" '{"task_list":{"name":"Transfer Me List"}}'
assert_status "201" "$RESPONSE_STATUS" "POST /task_lists.json (for transfer)"
TRANSFER_LIST_ID=$(echo "$RESPONSE_BODY" | jq -r '.data.id')

# ── CREATE TRANSFER — 422 unknown email ──────────────────────────────────────

api_post "$(transfer_create_path "$TRANSFER_LIST_ID")" '{"task_list_transfer":{"to_email":"nobody@nowhere.example.com"}}'
assert_status "422" "$RESPONSE_STATUS" "POST transfer (unknown email → 422)"
assert_failure_envelope "$RESPONSE_BODY" "transfer unknown email"

# ── CREATE TRANSFER — 422 self-transfer ──────────────────────────────────────

api_post "$(transfer_create_path "$TRANSFER_LIST_ID")" "{\"task_list_transfer\":{\"to_email\":\"${USER_A_EMAIL}\"}}"
assert_status "422" "$RESPONSE_STATUS" "POST transfer (self-transfer → 422)"

# ── CREATE TRANSFER — 404 bad list id ────────────────────────────────────────

api_post "$(transfer_create_path 999999999)" "{\"task_list_transfer\":{\"to_email\":\"${USER_B_EMAIL}\"}}"
assert_status "404" "$RESPONSE_STATUS" "POST transfer (bad list → 404)"

# ── CREATE TRANSFER — 201 success (for reject flow) ─────────────────────────

api_post "$(transfer_create_path "$TRANSFER_LIST_ID")" "{\"task_list_transfer\":{\"to_email\":\"${USER_B_EMAIL}\"}}"
assert_status "201" "$RESPONSE_STATUS" "POST /task_lists/:id/transfer.json (create)"
assert_success_envelope "$RESPONSE_BODY" "object" "transfer create"
assert_json_field "$RESPONSE_BODY" ".data.status" "pending" "transfer is pending"
assert_json_not_null "$RESPONSE_BODY" ".data.token" "transfer has token"

TRANSFER_TOKEN_1=$(echo "$RESPONSE_BODY" | jq -r '.data.token')

# ── SHOW TRANSFER — User B views ────────────────────────────────────────────

TOKEN="$TOKEN_B"

api_get "$(transfer_path "$TRANSFER_TOKEN_1")"
assert_status "200" "$RESPONSE_STATUS" "GET /transfers/:token.json (show)"
assert_success_envelope "$RESPONSE_BODY" "object" "transfer show"
assert_json_field "$RESPONSE_BODY" ".data.status" "pending" "show confirms pending"
assert_json_field "$RESPONSE_BODY" ".data.task_list_id" "$TRANSFER_LIST_ID" "show has correct list"

# ── SHOW TRANSFER — 404 bad token ───────────────────────────────────────────

api_get "$(transfer_path bad_token_999)"
assert_status "404" "$RESPONSE_STATUS" "GET /transfers/:bad_token.json (→ 404)"

# ── REJECT TRANSFER — User B rejects ────────────────────────────────────────

api_patch "$(transfer_path "$TRANSFER_TOKEN_1")" '{"action_type":"reject"}'
assert_status "200" "$RESPONSE_STATUS" "PATCH /transfers/:token.json (reject)"
assert_json_field "$RESPONSE_BODY" ".data.status" "rejected" "transfer is rejected"

# ── CREATE TRANSFER — 201 again (for accept flow) ───────────────────────────

TOKEN="$TOKEN_A"

api_post "$(transfer_create_path "$TRANSFER_LIST_ID")" "{\"task_list_transfer\":{\"to_email\":\"${USER_B_EMAIL}\"}}"
assert_status "201" "$RESPONSE_STATUS" "POST /task_lists/:id/transfer.json (create for accept)"

TRANSFER_TOKEN_2=$(echo "$RESPONSE_BODY" | jq -r '.data.token')

# ── ACCEPT TRANSFER — User B accepts ────────────────────────────────────────

TOKEN="$TOKEN_B"

api_patch "$(transfer_path "$TRANSFER_TOKEN_2")" '{"action_type":"accept"}'
assert_status "200" "$RESPONSE_STATUS" "PATCH /transfers/:token.json (accept)"
assert_json_field "$RESPONSE_BODY" ".data.status" "accepted" "transfer is accepted"

# ── VERIFY: list moved to User B ────────────────────────────────────────────

api_get "$(task_lists_path)"
assert_status "200" "$RESPONSE_STATUS" "GET /task_lists.json (User B after accept)"

TRANSFERRED_LIST=$(echo "$RESPONSE_BODY" | jq -r ".data[] | select(.id == ${TRANSFER_LIST_ID}) | .name")
if [ "$TRANSFERRED_LIST" = "Transfer Me List" ]; then
  echo -e "  ${GREEN}PASS${NC} transferred list appears in User B's lists"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC} transferred list not found in User B's lists"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# ── VERIFY: list gone from User A ───────────────────────────────────────────

TOKEN="$TOKEN_A"

api_get "$(task_lists_path)"
assert_status "200" "$RESPONSE_STATUS" "GET /task_lists.json (User A after accept)"

GONE_LIST=$(echo "$RESPONSE_BODY" | jq -r ".data[] | select(.id == ${TRANSFER_LIST_ID}) | .name")
if [ -z "$GONE_LIST" ]; then
  echo -e "  ${GREEN}PASS${NC} transferred list no longer in User A's lists"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC} transferred list still appears in User A's lists"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# ── ACCEPT/REJECT already processed — should fail ───────────────────────────

TOKEN="$TOKEN_B"

api_patch "$(transfer_path "$TRANSFER_TOKEN_2")" '{"action_type":"accept"}'
assert_status "422" "$RESPONSE_STATUS" "PATCH /transfers/:token.json (already accepted → 422)"

# ── Restore TOKEN ────────────────────────────────────────────────────────────

TOKEN="$SAVED_TOKEN"
