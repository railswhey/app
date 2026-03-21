class AddRoleAndWorkspaceToWorkspaceMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :workspace_members, :role, :string, limit: 16
    add_reference :workspace_members, :workspace, null: true, foreign_key: true

    reversible do |dir|
      dir.up do
        # Backfill workspace_id via account_people → account_memberships → accounts → workspaces
        execute <<~SQL
          UPDATE workspace_members
          SET workspace_id = (
            SELECT workspaces.id
            FROM account_people
            JOIN account_memberships ON account_memberships.person_id = account_people.id
            JOIN accounts ON accounts.id = account_memberships.account_id
            JOIN workspaces ON workspaces.uuid = accounts.uuid
            WHERE account_people.uuid = workspace_members.uuid
            LIMIT 1
          )
        SQL

        # Backfill role from account_memberships via shared UUID
        execute <<~SQL
          UPDATE workspace_members
          SET role = (
            SELECT account_memberships.role
            FROM account_people
            JOIN account_memberships ON account_memberships.person_id = account_people.id
            WHERE account_people.uuid = workspace_members.uuid
            LIMIT 1
          )
        SQL
      end
    end
  end
end
