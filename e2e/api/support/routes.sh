#!/usr/bin/env bash
# Route path helpers — single source of truth for all URL paths
# When routes change, update only this file.

# ── Task Lists ────────────────────────────────────────────────────────────────

task_lists_path()           { echo "/task_lists.json"; }
task_list_path()            { echo "/task_lists/${1}.json"; }

# ── Task Items (nested under task list) ───────────────────────────────────────

task_items_path()           { echo "/task_lists/${1}/task_items.json"; }
task_item_path()            { echo "/task_lists/${1}/task_items/${2}.json"; }
task_item_complete_path()   { echo "/task_lists/${1}/task_items/${2}/complete.json"; }
task_item_incomplete_path() { echo "/task_lists/${1}/task_items/${2}/incomplete.json"; }
task_item_move_path()       { echo "/task_lists/${1}/task_items/${2}/move.json"; }

# ── My Tasks ──────────────────────────────────────────────────────────────────

my_tasks_path()             { echo "/my_tasks.json"; }

# ── Search ────────────────────────────────────────────────────────────────────

search_path()               { echo "/search.json"; }

# ── Memberships (account-scoped) ──────────────────────────────────────────────

memberships_path()          { echo "/account/memberships.json"; }
membership_path()           { echo "/account/memberships/${1}.json"; }

# ── Invitations (account-scoped + public token-based) ─────────────────────────

account_invitations_path()  { echo "/account/invitations.json"; }
account_invitation_path()   { echo "/account/invitations/${1}.json"; }
invitation_path()           { echo "/invitations/${1}.json"; }

# ── Users ─────────────────────────────────────────────────────────────────────

users_path()                { echo "/users.json"; }
user_session_path()         { echo "/users/session.json"; }
user_token_path()           { echo "/users/token.json"; }
user_profile_path()         { echo "/users/profile.json"; }
user_password_path()        { echo "/users/password.json"; }
user_password_reset_path()  { echo "/users/${1}/password.json"; }

# ── Transfers ─────────────────────────────────────────────────────────────────

transfer_create_path()      { echo "/task_lists/${1}/transfer.json"; }
transfer_path()             { echo "/transfers/${1}.json"; }
