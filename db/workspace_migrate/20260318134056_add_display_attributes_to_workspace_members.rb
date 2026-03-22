class AddDisplayAttributesToWorkspaceMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :workspace_members, :username, :string
    add_column :workspace_members, :email, :string
  end
end
