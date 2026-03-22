# frozen_string_literal: true

# After multi-database split (7C), the primary database retains tables
# from legacy migrations that now live in per-domain databases.
# This migration cleans up those ghost tables.
class DropLegacyTaskTables < ActiveRecord::Migration[8.1]
  def up
    # Legacy task tables (pre-workspace bounded context)
    drop_table :task_list_transfers, if_exists: true
    drop_table :task_comments, if_exists: true
    drop_table :task_items, if_exists: true
    drop_table :task_lists, if_exists: true

    # Account tables — now live in account database
    drop_table :account_invitations, if_exists: true
    drop_table :account_memberships, if_exists: true
    drop_table :account_people, if_exists: true
    drop_table :accounts, if_exists: true

    # Workspace tables — now live in workspace database
    drop_table :workspace_list_transfers, if_exists: true
    drop_table :workspace_comments, if_exists: true
    drop_table :workspace_tasks, if_exists: true
    drop_table :workspace_lists, if_exists: true
    drop_table :workspace_members, if_exists: true
    drop_table :workspaces, if_exists: true
  end
end
