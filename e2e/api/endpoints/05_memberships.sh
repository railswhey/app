#!/usr/bin/env bash
# Test: Memberships listing + removal
# Docs: GET /account/memberships.json
#       DELETE /account/memberships/:id.json

section "Members"

# 1. List members — 200
api_get "$(memberships_path)"
assert_status "200" "$RESPONSE_STATUS" "GET /account/memberships.json"
assert_success_envelope "$RESPONSE_BODY" "array" "memberships index"

MEMBER_COUNT=$(echo "$RESPONSE_BODY" | jq '.data | length')
if [ "$MEMBER_COUNT" -ge 1 ]; then
  echo -e "  ${GREEN}PASS${NC} memberships list has >= 1 member (got $MEMBER_COUNT)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC} memberships list expected >= 1 member, got $MEMBER_COUNT"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# 2. Delete a member — 404 bogus id
api_delete "$(membership_path 999999999)"
assert_status "404" "$RESPONSE_STATUS" "DELETE /account/memberships/:id.json (bogus id → 404)"
