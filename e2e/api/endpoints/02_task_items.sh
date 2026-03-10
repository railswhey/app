#!/usr/bin/env bash
# Test: Task Items CRUD + complete/incomplete/move + error scenarios
# Mirrors: test/integration/api/v1/task/items/{index,create,update,destroy,complete,incomplete}_test.rb

section "Task Items"

# Create a task list to work with
api_post "$(task_lists_path)" '{"task_list":{"name":"Items Test List"}}'
assert_status "201" "$RESPONSE_STATUS" "POST /task_lists.json (for items)"
ITEMS_LIST_ID=$(echo "$RESPONSE_BODY" | jq -r '.data.id')

# ── CREATE — happy path ──────────────────────────────────────────────────────

api_post "$(task_items_path "$ITEMS_LIST_ID")" '{"task_item":{"name":"Test Task","description":"A smoke test task"}}'
assert_status "201" "$RESPONSE_STATUS" "POST /task_items.json (create)"
assert_success_envelope "$RESPONSE_BODY" "object" "task_items create"
assert_json_field "$RESPONSE_BODY" ".data.name" "Test Task" "created item name"
assert_json_not_null "$RESPONSE_BODY" ".data.id" "created item has id"
assert_json_not_null "$RESPONSE_BODY" ".data.created_at" "created item has created_at"
assert_json_null "$RESPONSE_BODY" ".data.completed_at" "created item completed_at is null"

ITEM_ID=$(echo "$RESPONSE_BODY" | jq -r '.data.id')

# ── CREATE — 400 missing params ─────────────────────────────────────────────

api_post "$(task_items_path "$ITEMS_LIST_ID")" '{}'
assert_status "400" "$RESPONSE_STATUS" "POST /task_items.json (missing params → 400)"
assert_failure_envelope "$RESPONSE_BODY" "create missing params"

# ── CREATE — 422 blank name ─────────────────────────────────────────────────

api_post "$(task_items_path "$ITEMS_LIST_ID")" '{"task_item":{"name":""}}'
assert_status "422" "$RESPONSE_STATUS" "POST /task_items.json (blank name → 422)"
assert_failure_envelope "$RESPONSE_BODY" "create blank name"

# ── CREATE — 404 bad list id ────────────────────────────────────────────────

api_post "$(task_items_path 999999999)" '{"task_item":{"name":"Nope"}}'
assert_status "404" "$RESPONSE_STATUS" "POST /task_items.json (bad list → 404)"

# ── INDEX — unfiltered ───────────────────────────────────────────────────────

api_get "$(task_items_path "$ITEMS_LIST_ID")"
assert_status "200" "$RESPONSE_STATUS" "GET /task_items.json (unfiltered)"
assert_success_envelope "$RESPONSE_BODY" "array" "task_items index unfiltered"

# ── INDEX — filter=incomplete ────────────────────────────────────────────────

api_get "$(task_items_path "$ITEMS_LIST_ID")?filter=incomplete"
assert_status "200" "$RESPONSE_STATUS" "GET /task_items.json?filter=incomplete"
assert_success_envelope "$RESPONSE_BODY" "array" "task_items index incomplete"

# ── INDEX — 404 bad list id ─────────────────────────────────────────────────

api_get "$(task_items_path 999999999)"
assert_status "404" "$RESPONSE_STATUS" "GET /task_items.json (bad list → 404)"

# ── SHOW ─────────────────────────────────────────────────────────────────────

api_get "$(task_item_path "$ITEMS_LIST_ID" "$ITEM_ID")"
assert_status "200" "$RESPONSE_STATUS" "GET /task_items/:id.json"
assert_success_envelope "$RESPONSE_BODY" "object" "task_items show"
assert_json_field "$RESPONSE_BODY" ".data.name" "Test Task" "fetched item name"
assert_json_field "$RESPONSE_BODY" ".data.task_list_id" "$ITEMS_LIST_ID" "fetched item belongs to correct list"

# ── SHOW — 404 bad item id ──────────────────────────────────────────────────

api_get "$(task_item_path "$ITEMS_LIST_ID" 999999999)"
assert_status "404" "$RESPONSE_STATUS" "GET /task_items/:bad_id.json (→ 404)"

# ── UPDATE — happy path ─────────────────────────────────────────────────────

api_put "$(task_item_path "$ITEMS_LIST_ID" "$ITEM_ID")" '{"task_item":{"name":"Updated Task"}}'
assert_status "200" "$RESPONSE_STATUS" "PUT /task_items/:id.json (update)"
assert_success_envelope "$RESPONSE_BODY" "object" "task_items update"
assert_json_field "$RESPONSE_BODY" ".data.name" "Updated Task" "updated item name"

# ── UPDATE — 400 missing params ─────────────────────────────────────────────

api_put "$(task_item_path "$ITEMS_LIST_ID" "$ITEM_ID")" '{}'
assert_status "400" "$RESPONSE_STATUS" "PUT /task_items/:id.json (missing params → 400)"

# ── UPDATE — 422 blank name ─────────────────────────────────────────────────

api_put "$(task_item_path "$ITEMS_LIST_ID" "$ITEM_ID")" '{"task_item":{"name":""}}'
assert_status "422" "$RESPONSE_STATUS" "PUT /task_items/:id.json (blank name → 422)"

# ── UPDATE — 404 bad item id ────────────────────────────────────────────────

api_put "$(task_item_path "$ITEMS_LIST_ID" 999999999)" '{"task_item":{"name":"Nope"}}'
assert_status "404" "$RESPONSE_STATUS" "PUT /task_items/:bad_id.json (→ 404)"

# ── COMPLETE ─────────────────────────────────────────────────────────────────

api_put "$(task_item_complete_path "$ITEMS_LIST_ID" "$ITEM_ID")"
assert_status "200" "$RESPONSE_STATUS" "PUT /task_items/:id/complete.json"
assert_success_envelope "$RESPONSE_BODY" "object" "task_items complete"
assert_json_not_null "$RESPONSE_BODY" ".data.completed_at" "completed_at is set after complete"

# ── INDEX — filter=completed ─────────────────────────────────────────────────

api_get "$(task_items_path "$ITEMS_LIST_ID")?filter=completed"
assert_status "200" "$RESPONSE_STATUS" "GET /task_items.json?filter=completed"
assert_success_envelope "$RESPONSE_BODY" "array" "task_items index completed"

COMPLETED_COUNT=$(echo "$RESPONSE_BODY" | jq '.data | length')
if [ "$COMPLETED_COUNT" -ge 1 ]; then
  echo -e "  ${GREEN}PASS${NC} completed filter returns >= 1 item (got $COMPLETED_COUNT)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC} completed filter expected >= 1 item, got $COMPLETED_COUNT"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# ── COMPLETE — 404 bad item id ──────────────────────────────────────────────

api_put "$(task_item_complete_path "$ITEMS_LIST_ID" 999999999)"
assert_status "404" "$RESPONSE_STATUS" "PUT /task_items/:bad_id/complete.json (→ 404)"

# ── INCOMPLETE ───────────────────────────────────────────────────────────────

api_put "$(task_item_incomplete_path "$ITEMS_LIST_ID" "$ITEM_ID")"
assert_status "200" "$RESPONSE_STATUS" "PUT /task_items/:id/incomplete.json"
assert_success_envelope "$RESPONSE_BODY" "object" "task_items incomplete"
assert_json_null "$RESPONSE_BODY" ".data.completed_at" "completed_at is null after incomplete"

# ── INCOMPLETE — 404 bad item id ────────────────────────────────────────────

api_put "$(task_item_incomplete_path "$ITEMS_LIST_ID" 999999999)"
assert_status "404" "$RESPONSE_STATUS" "PUT /task_items/:bad_id/incomplete.json (→ 404)"

# ── MOVE ─────────────────────────────────────────────────────────────────────

api_put "$(task_item_move_path "$ITEMS_LIST_ID" "$ITEM_ID")" "{\"target_list_id\":${INBOX_ID}}"
assert_status "200" "$RESPONSE_STATUS" "PUT /task_items/:id/move.json"
assert_success_envelope "$RESPONSE_BODY" "object" "task_items move"
assert_json_field "$RESPONSE_BODY" ".data.task_list_id" "$INBOX_ID" "moved item belongs to target list"

# ── MOVE — 422 target not found ──────────────────────────────────────────────

api_put "$(task_item_move_path "$INBOX_ID" "$ITEM_ID")" '{"target_list_id":999999999}'
assert_status "422" "$RESPONSE_STATUS" "PUT /task_items/:id/move.json (bad target → 422)"

# ── MOVE — 422 same list ─────────────────────────────────────────────────────

api_put "$(task_item_move_path "$INBOX_ID" "$ITEM_ID")" "{\"target_list_id\":${INBOX_ID}}"
assert_status "422" "$RESPONSE_STATUS" "PUT /task_items/:id/move.json (same list → 422)"

# ── DELETE ───────────────────────────────────────────────────────────────────
# The move above relocated the item to INBOX.

api_delete "$(task_item_path "$INBOX_ID" "$ITEM_ID")"
assert_status "204" "$RESPONSE_STATUS" "DELETE /task_items/:id.json"

# ── DELETE — 404 already deleted ─────────────────────────────────────────────

api_delete "$(task_item_path "$INBOX_ID" "$ITEM_ID")"
assert_status "404" "$RESPONSE_STATUS" "DELETE /task_items/:id.json (already deleted → 404)"

# Cleanup: delete the test list
api_delete "$(task_list_path "$ITEMS_LIST_ID")"
assert_status "204" "$RESPONSE_STATUS" "DELETE /task_lists/:id.json (items cleanup)"
