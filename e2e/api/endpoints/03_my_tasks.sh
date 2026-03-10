#!/usr/bin/env bash
# Test: My Tasks listing
# Docs: GET /my_tasks.json?filter=incomplete|completed

section "My Tasks"

# 1. List my tasks (all)
api_get "$(my_tasks_path)"
assert_status "200" "$RESPONSE_STATUS" "GET /my_tasks.json"
assert_success_envelope "$RESPONSE_BODY" "array" "my_tasks all"

# 2. List my tasks (incomplete filter)
api_get "$(my_tasks_path)?filter=incomplete"
assert_status "200" "$RESPONSE_STATUS" "GET /my_tasks.json?filter=incomplete"
assert_success_envelope "$RESPONSE_BODY" "array" "my_tasks incomplete"

# 3. List my tasks (completed filter)
api_get "$(my_tasks_path)?filter=completed"
assert_status "200" "$RESPONSE_STATUS" "GET /my_tasks.json?filter=completed"
assert_success_envelope "$RESPONSE_BODY" "array" "my_tasks completed"
