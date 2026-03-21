# frozen_string_literal: true

class CreateWorkspacesBoundedContext < ActiveRecord::Migration[8.1]
  def up
    # --- New tables ---

    create_table :workspaces do |t|
      t.string :uuid, null: false
      t.timestamps
      t.index :uuid, unique: true
    end

    create_table :workspace_members do |t|
      t.string :uuid, null: false
      t.timestamps
      t.index :uuid, unique: true
    end

    # --- Add uuid to users ---

    add_column :users, :uuid, :string
    add_index :users, :uuid, unique: true

    # --- Rebuild task_lists as workspace_lists ---

    create_table :workspace_lists do |t|
      t.references :workspace, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.boolean :inbox, default: false, null: false
      t.timestamps
      t.index [ :workspace_id ], unique: true, where: "inbox", name: "index_workspace_lists_inbox"
    end

    drop_table :task_lists

    # --- Rebuild task_items as workspace_tasks ---

    create_table :workspace_tasks do |t|
      t.references :workspace_list, null: false, foreign_key: { to_table: :workspace_lists }
      t.references :assigned_member, foreign_key: { to_table: :workspace_members }
      t.string :name, null: false
      t.text :description
      t.datetime :completed_at
      t.timestamps
      t.index :completed_at
    end

    drop_table :task_items

    # --- Rebuild task_comments as workspace_comments ---

    create_table :workspace_comments do |t|
      t.references :commentable, polymorphic: true, null: false
      t.references :member, null: false, foreign_key: { to_table: :workspace_members }
      t.text :body, null: false
      t.timestamps
      t.index [ :commentable_type, :commentable_id, :created_at ], name: "index_workspace_comments_on_commentable_and_created_at"
    end

    drop_table :task_comments

    # --- Rebuild task_list_transfers as workspace_list_transfers ---

    create_table :workspace_list_transfers do |t|
      t.references :workspace_list, null: false, foreign_key: { to_table: :workspace_lists }
      t.references :from_workspace, null: false, foreign_key: { to_table: :workspaces }
      t.references :to_workspace,   null: false, foreign_key: { to_table: :workspaces }
      t.references :initiated_by,   null: false, foreign_key: { to_table: :workspace_members }
      t.string :token, null: false
      t.integer :status, default: 0, null: false
      t.timestamps
      t.index :token, unique: true
      t.index :status
    end

    drop_table :task_list_transfers
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
