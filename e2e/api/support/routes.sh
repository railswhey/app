#!/usr/bin/env bash
# Route path helpers — single source of truth for all URL paths
# When routes change, update only this file.

# ── Task Lists ────────────────────────────────────────────────────────────────

task_lists_path()           { echo "/api/v1/task/lists"; }
task_list_path()            { echo "/api/v1/task/lists/${1}"; }

# ── Task Items (nested under task list) ───────────────────────────────────────

task_items_path()           { echo "/api/v1/task/lists/${1}/items"; }
task_item_path()            { echo "/api/v1/task/lists/${1}/items/${2}"; }
task_item_complete_path()   { echo "/api/v1/task/lists/${1}/item/complete/${2}"; }
task_item_incomplete_path() { echo "/api/v1/task/lists/${1}/item/incomplete/${2}"; }
task_item_move_path()       { echo "/api/v1/task/lists/${1}/item/moves?task_item_id=${2}"; }

# ── My Tasks ──────────────────────────────────────────────────────────────────

my_tasks_path()             { echo "/api/v1/task/item/assignments"; }

# ── Search ────────────────────────────────────────────────────────────────────

search_path()               { echo "/api/v1/account/search"; }

# ── Memberships (account-scoped) ──────────────────────────────────────────────

memberships_path()          { echo "/api/v1/account/memberships"; }
membership_path()           { echo "/api/v1/account/memberships/${1}"; }

# ── Invitations (account-scoped + public token-based) ─────────────────────────

account_invitations_path()  { echo "/api/v1/account/invitations"; }
account_invitation_path()   { echo "/api/v1/account/invitations/${1}"; }
invitation_path()           { echo "/api/v1/account/invitations/acceptance?token=${1}"; }

# ── Users ─────────────────────────────────────────────────────────────────────

users_path()                { echo "/api/v1/user/registrations"; }
user_path()                 { echo "/api/v1/user/registration"; }
user_session_path()         { echo "/api/v1/user/session"; }
user_token_path()           { echo "/api/v1/user/settings/token"; }
user_profile_path()         { echo "/api/v1/user/settings/profile"; }
user_settings_password_path() { echo "/api/v1/user/settings/password"; }
user_password_path()        { echo "/api/v1/user/password"; }
user_password_reset_path()  { echo "/api/v1/user/password?token=${1}"; }

# ── Transfers ─────────────────────────────────────────────────────────────────

transfer_create_path()      { echo "/api/v1/task/lists/${1}/transfer"; }
transfer_path()             { echo "/api/v1/account/transfers/response?token=${1}"; }
