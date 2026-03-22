class AddRoleAndWorkspaceToWorkspaceMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :workspace_members, :role, :string, limit: 16
    add_reference :workspace_members, :workspace, null: true, foreign_key: true
  end
end
