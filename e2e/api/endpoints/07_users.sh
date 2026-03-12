#!/usr/bin/env bash
# Test: User lifecycle endpoints (register, login, token, profile, password, delete)
# These endpoints have full JSON support but are not yet in the API docs.
# Mirrors: test/integration/api/v1/users/{registrations,sessions,tokens,profiles,passwords}_test.rb

section "Users"

REG_TS="$(date +%s)"
REG_EMAIL="smoke-reg-${REG_TS}@example.com"
REG_USERNAME="smokereg${REG_TS}"
REG_PASSWORD="SmokeTe5t!Reg1"

# ── REGISTER — 400 missing params ────────────────────────────────────────────

api_post "$(users_path)" '{}' "none"
assert_status "400" "$RESPONSE_STATUS" "POST /users.json (missing params → 400)"

# ── REGISTER — 422 invalid email ─────────────────────────────────────────────

api_post "$(users_path)" '{"user":{"email":"bad","username":"x","password":"short","password_confirmation":"short"}}' "none"
assert_status "422" "$RESPONSE_STATUS" "POST /users.json (invalid data → 422)"

# ── REGISTER — 201 success ───────────────────────────────────────────────────

api_post "$(users_path)" "{\"user\":{\"email\":\"${REG_EMAIL}\",\"username\":\"${REG_USERNAME}\",\"password\":\"${REG_PASSWORD}\",\"password_confirmation\":\"${REG_PASSWORD}\"}}" "none"
assert_status "201" "$RESPONSE_STATUS" "POST /users.json (register)"
assert_success_envelope "$RESPONSE_BODY" "object" "register response"
assert_json_not_null "$RESPONSE_BODY" ".data.user_token" "register returns token"

REG_TOKEN=$(echo "$RESPONSE_BODY" | jq -r '.data.user_token')

# ── LOGIN — 400 missing params ───────────────────────────────────────────────

api_post "$(user_session_path)" '{}' "none"
assert_status "400" "$RESPONSE_STATUS" "POST /users/session.json (missing params → 400)"

# ── LOGIN — 401 bad credentials ──────────────────────────────────────────────

api_post "$(user_session_path)" '{"user":{"email":"nobody@nowhere.com","password":"wrong"}}' "none"
assert_status "401" "$RESPONSE_STATUS" "POST /users/session.json (bad creds → 401)"
assert_failure_envelope "$RESPONSE_BODY" "login bad creds"

# ── LOGIN — 200 success ─────────────────────────────────────────────────────

api_post "$(user_session_path)" "{\"user\":{\"email\":\"${REG_EMAIL}\",\"password\":\"${REG_PASSWORD}\"}}" "none"
assert_status "200" "$RESPONSE_STATUS" "POST /users/session.json (login)"
assert_success_envelope "$RESPONSE_BODY" "object" "login response"
assert_json_not_null "$RESPONSE_BODY" ".data.user_token" "login returns token"

# ── TOKEN REFRESH — 401 no auth ──────────────────────────────────────────────

api_put "$(user_token_path)" '{}' "none"
assert_status "401" "$RESPONSE_STATUS" "PUT /users/token.json (no auth → 401)"

# ── TOKEN REFRESH — 200 success ──────────────────────────────────────────────

api_put "$(user_token_path)" '{}' "$REG_TOKEN"
assert_status "200" "$RESPONSE_STATUS" "PUT /users/token.json (refresh)"
assert_success_envelope "$RESPONSE_BODY" "object" "token refresh response"
assert_json_not_null "$RESPONSE_BODY" ".data.user_token" "refresh returns new token"

REG_TOKEN=$(echo "$RESPONSE_BODY" | jq -r '.data.user_token')

# ── PROFILE UPDATE — 400 missing params ──────────────────────────────────────

api_put "$(user_profile_path)" '{}' "$REG_TOKEN"
assert_status "400" "$RESPONSE_STATUS" "PUT /users/profile.json (missing params → 400)"

# ── PROFILE UPDATE — 422 wrong current password ─────────────────────────────

api_put "$(user_profile_path)" '{"user":{"current_password":"wrong","password":"NewPass!123","password_confirmation":"NewPass!123"}}' "$REG_TOKEN"
assert_status "422" "$RESPONSE_STATUS" "PUT /users/profile.json (wrong current_password → 422)"

# ── PROFILE UPDATE — 200 success ────────────────────────────────────────────

api_put "$(user_profile_path)" "{\"user\":{\"current_password\":\"${REG_PASSWORD}\",\"password\":\"SmokeTe5t!Reg2\",\"password_confirmation\":\"SmokeTe5t!Reg2\"}}" "$REG_TOKEN"
assert_status "200" "$RESPONSE_STATUS" "PUT /users/profile.json (change password)"
REG_PASSWORD="SmokeTe5t!Reg2"

# ── PASSWORD RESET REQUEST — 400 missing params ─────────────────────────────

api_post "$(user_password_path)" '{}' "none"
assert_status "400" "$RESPONSE_STATUS" "POST /users/password.json (missing params → 400)"

# ── PASSWORD RESET REQUEST — 200 (always succeeds, even unknown email) ──────

api_post "$(user_password_path)" '{"user":{"email":"unknown-smoke@example.com"}}' "none"
assert_status "200" "$RESPONSE_STATUS" "POST /users/password.json (unknown email → still 200)"

api_post "$(user_password_path)" "{\"user\":{\"email\":\"${REG_EMAIL}\"}}" "none"
assert_status "200" "$RESPONSE_STATUS" "POST /users/password.json (known email → 200)"

# ── PASSWORD RESET UPDATE — 422 invalid token ───────────────────────────────

api_put "$(user_password_reset_path fake_token_123)" '{"user":{"password":"NewPass!123","password_confirmation":"NewPass!123"}}' "none"
assert_status "422" "$RESPONSE_STATUS" "PUT /users/:token/password.json (bad token → 422)"

# ── PASSWORD RESET UPDATE — 200 success ─────────────────────────────────────

RESET_TOKEN=$(cd "$PROJECT_ROOT" && bin/rails runner "print User.find_by(email: '${REG_EMAIL}').generate_token_for(:reset_password)" 2>/dev/null)

if [ -n "$RESET_TOKEN" ]; then
  api_put "$(user_password_reset_path "$RESET_TOKEN")" '{"user":{"password":"SmokeTe5t!Reg3","password_confirmation":"SmokeTe5t!Reg3"}}' "none"
  assert_status "200" "$RESPONSE_STATUS" "PUT /users/:token/password.json (reset password)"
else
  echo -e "  ${RED}FAIL${NC} could not generate password reset token via rails runner"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# ── DELETE ACCOUNT — 401 no auth ─────────────────────────────────────────────

api_delete "$(user_path)" "none"
assert_status "401" "$RESPONSE_STATUS" "DELETE /users.json (no auth → 401)"

# ── DELETE ACCOUNT — 204 success ─────────────────────────────────────────────

api_delete "$(user_path)" "$REG_TOKEN"
assert_status "204" "$RESPONSE_STATUS" "DELETE /users.json (delete account)"
