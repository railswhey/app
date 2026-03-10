class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.references :account,    null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string     :email,      null: false
      t.string     :token,      null: false
      t.datetime   :accepted_at
      t.timestamps
    end
    add_index :invitations, :token, unique: true
    add_index :invitations, [ :account_id, :email ], unique: true
  end
end
