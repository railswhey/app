#!/usr/bin/env bash
# Test: Authentication — 401 for missing/invalid tokens
# Mirrors: all Rails integration tests that assert 401

section "Authentication"

# 1. No Authorization header at all
api_get "$(task_lists_path)" "none"
assert_status "401" "$RESPONSE_STATUS" "GET $(task_lists_path) without token"
assert_failure_envelope "$RESPONSE_BODY" "no-token response"

# 2. Invalid/garbage token
api_get "$(task_lists_path)" "invalid_garbage_token_12345"
assert_status "401" "$RESPONSE_STATUS" "GET $(task_lists_path) with bad token"
assert_failure_envelope "$RESPONSE_BODY" "bad-token response"

# 3. POST with no token
api_post "$(task_lists_path)" '{"task_list":{"name":"Should Fail"}}' "none"
assert_status "401" "$RESPONSE_STATUS" "POST $(task_lists_path) without token"

# 4. Task items endpoint with no token
api_get "$(task_items_path 999999)" "none"
assert_status "401" "$RESPONSE_STATUS" "GET /task_items.json without token"
