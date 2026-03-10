#!/usr/bin/env bash
# Test: Task Lists CRUD + error scenarios
# Mirrors: test/integration/api/v1/task/lists/{index,create,update,destroy}_test.rb

section "Task Lists"

# ── INDEX ──────────────────────────────────────────────────────────────────────

api_get "$(task_lists_path)"
assert_status "200" "$RESPONSE_STATUS" "GET /task_lists.json"
assert_success_envelope "$RESPONSE_BODY" "array" "task_lists index"

INBOX_ID=$(echo "$RESPONSE_BODY" | jq -r '.data[] | select(.inbox == true) | .id')
assert_json_not_null "$RESPONSE_BODY" '.data[] | select(.inbox == true) | .id' "Inbox exists in list"

# ── CREATE — happy path ───────────────────────────────────────────────────────

api_post "$(task_lists_path)" '{"task_list":{"name":"API Test List","description":"Created by smoke tests"}}'
assert_status "201" "$RESPONSE_STATUS" "POST /task_lists.json (create)"
assert_success_envelope "$RESPONSE_BODY" "object" "task_lists create"
assert_json_field "$RESPONSE_BODY" ".data.name" "API Test List" "created list name"
assert_json_not_null "$RESPONSE_BODY" ".data.id" "created list has id"
assert_json_not_null "$RESPONSE_BODY" ".data.created_at" "created list has created_at"

LIST_ID=$(echo "$RESPONSE_BODY" | jq -r '.data.id')

# ── CREATE — 400 missing params ──────────────────────────────────────────────

api_post "$(task_lists_path)" '{}'
assert_status "400" "$RESPONSE_STATUS" "POST /task_lists.json (missing params → 400)"
assert_failure_envelope "$RESPONSE_BODY" "create missing params"

# ── CREATE — 422 blank name ──────────────────────────────────────────────────

api_post "$(task_lists_path)" '{"task_list":{"name":""}}'
assert_status "422" "$RESPONSE_STATUS" "POST /task_lists.json (blank name → 422)"
assert_failure_envelope "$RESPONSE_BODY" "create blank name"

# ── SHOW ──────────────────────────────────────────────────────────────────────

api_get "$(task_list_path "$LIST_ID")"
assert_status "200" "$RESPONSE_STATUS" "GET /task_lists/:id.json"
assert_success_envelope "$RESPONSE_BODY" "object" "task_lists show"
assert_json_field "$RESPONSE_BODY" ".data.name" "API Test List" "fetched list name"
assert_json_field "$RESPONSE_BODY" ".data.id" "$LIST_ID" "fetched list id matches"

# ── SHOW — 404 not found ─────────────────────────────────────────────────────

api_get "$(task_list_path 999999999)"
assert_status "404" "$RESPONSE_STATUS" "GET /task_lists/:bad_id.json (→ 404)"

# ── UPDATE — happy path ──────────────────────────────────────────────────────

api_put "$(task_list_path "$LIST_ID")" '{"task_list":{"name":"Renamed Test List"}}'
assert_status "200" "$RESPONSE_STATUS" "PUT /task_lists/:id.json (update)"
assert_success_envelope "$RESPONSE_BODY" "object" "task_lists update"
assert_json_field "$RESPONSE_BODY" ".data.name" "Renamed Test List" "updated list name"

# ── UPDATE — 400 missing params ─────────────────────────────────────────────

api_put "$(task_list_path "$LIST_ID")" '{}'
assert_status "400" "$RESPONSE_STATUS" "PUT /task_lists/:id.json (missing params → 400)"
assert_failure_envelope "$RESPONSE_BODY" "update missing params"

# ── UPDATE — 422 blank name ─────────────────────────────────────────────────

api_put "$(task_list_path "$LIST_ID")" '{"task_list":{"name":""}}'
assert_status "422" "$RESPONSE_STATUS" "PUT /task_lists/:id.json (blank name → 422)"
assert_failure_envelope "$RESPONSE_BODY" "update blank name"

# ── UPDATE — 404 not found ──────────────────────────────────────────────────

api_put "$(task_list_path 999999999)" '{"task_list":{"name":"Nope"}}'
assert_status "404" "$RESPONSE_STATUS" "PUT /task_lists/:bad_id.json (→ 404)"

# ── UPDATE — 403 inbox protection ───────────────────────────────────────────

api_put "$(task_list_path "$INBOX_ID")" '{"task_list":{"name":"Hacked Inbox"}}'
assert_status "403" "$RESPONSE_STATUS" "PUT /task_lists/:inbox_id.json (→ 403)"
assert_failure_envelope "$RESPONSE_BODY" "inbox update protection"

# ── DELETE — happy path ──────────────────────────────────────────────────────

api_delete "$(task_list_path "$LIST_ID")"
assert_status "204" "$RESPONSE_STATUS" "DELETE /task_lists/:id.json"

# ── DELETE — 404 already deleted ─────────────────────────────────────────────

api_delete "$(task_list_path "$LIST_ID")"
assert_status "404" "$RESPONSE_STATUS" "DELETE /task_lists/:id.json (already deleted → 404)"

# ── DELETE — 403 inbox protection ────────────────────────────────────────────

api_delete "$(task_list_path "$INBOX_ID")"
assert_status "403" "$RESPONSE_STATUS" "DELETE /task_lists/:inbox_id.json (→ 403)"
assert_failure_envelope "$RESPONSE_BODY" "inbox delete protection"

# Export INBOX_ID for use in later test files
export INBOX_ID
