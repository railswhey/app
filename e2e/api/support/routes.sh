#!/usr/bin/env bash
# Route path helpers — single source of truth for all URL paths
# When routes change, update only this file.

# ── Task Lists ────────────────────────────────────────────────────────────────

task_lists_path()           { echo "/task/lists.json"; }
task_list_path()            { echo "/task/lists/${1}.json"; }

# ── Task Items (nested under task list) ───────────────────────────────────────

task_items_path()           { echo "/task/lists/${1}/items.json"; }
task_item_path()            { echo "/task/lists/${1}/items/${2}.json"; }
task_item_complete_path()   { echo "/task/lists/${1}/item/complete/${2}.json"; }
task_item_incomplete_path() { echo "/task/lists/${1}/item/incomplete/${2}.json"; }
task_item_move_path()       { echo "/task/lists/${1}/item/moves.json?task_item_id=${2}"; }

# ── My Tasks ──────────────────────────────────────────────────────────────────

my_tasks_path()             { echo "/task/item/assignments.json"; }

# ── Search ────────────────────────────────────────────────────────────────────

search_path()               { echo "/account/search.json"; }

# ── Memberships (account-scoped) ──────────────────────────────────────────────

memberships_path()          { echo "/account/memberships.json"; }
membership_path()           { echo "/account/memberships/${1}.json"; }

# ── Invitations (account-scoped + public token-based) ─────────────────────────

account_invitations_path()  { echo "/account/invitations.json"; }
account_invitation_path()   { echo "/account/invitations/${1}.json"; }
invitation_path()           { echo "/account/invitations/acceptance.json?token=${1}"; }

# ── Users ─────────────────────────────────────────────────────────────────────

users_path()                { echo "/user/registrations.json"; }
user_path()                 { echo "/user/registration.json"; }
user_session_path()         { echo "/user/session.json"; }
user_token_path()           { echo "/user/settings/token.json"; }
user_profile_path()           { echo "/user/settings/profile.json"; }
user_settings_password_path() { echo "/user/settings/password.json"; }
user_password_path()        { echo "/user/password.json"; }
user_password_reset_path()  { echo "/user/password.json?token=${1}"; }

# ── Transfers ─────────────────────────────────────────────────────────────────

transfer_create_path()      { echo "/task/lists/${1}/transfer.json"; }
transfer_path()             { echo "/account/transfers/response.json?token=${1}"; }
