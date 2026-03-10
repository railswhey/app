#!/usr/bin/env bash
# Test: Invitations CRUD
# Docs: GET    /account/invitations.json        (list)
#       POST   /account/invitations.json        (create)
#       DELETE  /account/invitations/:id.json    (destroy)
#       GET    /invitations/:token.json          (show — public)
#       PATCH  /invitations/:token.json          (accept — public)

section "Invitations"

# ── INDEX — 200 ───────────────────────────────────────────────────────────────

api_get "$(account_invitations_path)"
assert_status "200" "$RESPONSE_STATUS" "GET /account/invitations.json"
assert_success_envelope "$RESPONSE_BODY" "array" "invitations index"

# ── CREATE — 400 missing params ───────────────────────────────────────────────

api_post "$(account_invitations_path)" '{}'
assert_status "400" "$RESPONSE_STATUS" "POST /account/invitations.json (missing params → 400)"

# ── CREATE — 422 invalid email ────────────────────────────────────────────────

api_post "$(account_invitations_path)" '{"invitation":{"email":"not-an-email"}}'
assert_status "422" "$RESPONSE_STATUS" "POST /account/invitations.json (invalid email → 422)"

# ── CREATE — 201 success ─────────────────────────────────────────────────────

api_post "$(account_invitations_path)" '{"invitation":{"email":"smoke-test-invite@example.com"}}'
assert_status "201" "$RESPONSE_STATUS" "POST /account/invitations.json (create)"
assert_success_envelope "$RESPONSE_BODY" "object" "invitation create"
assert_json_not_null "$RESPONSE_BODY" ".data.id" "invitation has id"
assert_json_not_null "$RESPONSE_BODY" ".data.token" "invitation has token"
assert_json_field "$RESPONSE_BODY" ".data.email" "smoke-test-invite@example.com" "invitation email"

INVITE_ID=$(echo "$RESPONSE_BODY" | jq -r '.data.id')
INVITE_TOKEN=$(echo "$RESPONSE_BODY" | jq -r '.data.token')

# ── CREATE — 422 duplicate email ─────────────────────────────────────────────

api_post "$(account_invitations_path)" '{"invitation":{"email":"smoke-test-invite@example.com"}}'
assert_status "422" "$RESPONSE_STATUS" "POST /account/invitations.json (duplicate → 422)"

# ── SHOW — 200 by token (User B views, not yet a member of User A's account) ─

SAVED_TOKEN="$TOKEN"
TOKEN="$TOKEN_B"

api_get "$(invitation_path "$INVITE_TOKEN")"
assert_status "200" "$RESPONSE_STATUS" "GET /invitations/:token.json (show)"
assert_success_envelope "$RESPONSE_BODY" "object" "invitation show"

# ── SHOW — 404 bad token ─────────────────────────────────────────────────────

api_get "$(invitation_path fake_token_123)"
assert_status "404" "$RESPONSE_STATUS" "GET /invitations/:token.json (bad token → 404)"

# ── ACCEPT — 404 bad token ───────────────────────────────────────────────────

api_patch "$(invitation_path fake_token_123)" '{}'
assert_status "404" "$RESPONSE_STATUS" "PATCH /invitations/:token.json (bad token → 404)"

# ── ACCEPT — 200 success (User B accepts invitation to User A's account) ─────

api_patch "$(invitation_path "$INVITE_TOKEN")" '{}'
assert_status "200" "$RESPONSE_STATUS" "PATCH /invitations/:token.json (accept)"
assert_success_envelope "$RESPONSE_BODY" "object" "invitation accept"
assert_json_not_null "$RESPONSE_BODY" ".data.accepted_at" "accepted_at is set"

# ── ACCEPT — 422 already accepted ────────────────────────────────────────────

api_patch "$(invitation_path "$INVITE_TOKEN")" '{}'
assert_status "422" "$RESPONSE_STATUS" "PATCH /invitations/:token.json (already accepted → 422)"

TOKEN="$SAVED_TOKEN"

# ── DELETE — 204 ─────────────────────────────────────────────────────────────

api_delete "$(account_invitation_path "$INVITE_ID")"
assert_status "204" "$RESPONSE_STATUS" "DELETE /account/invitations/:id.json"

# ── DELETE — 404 already deleted ──────────────────────────────────────────────

api_delete "$(account_invitation_path "$INVITE_ID")"
assert_status "404" "$RESPONSE_STATUS" "DELETE /account/invitations/:id.json (already deleted → 404)"
