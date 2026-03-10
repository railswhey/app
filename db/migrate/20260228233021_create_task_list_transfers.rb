class CreateTaskListTransfers < ActiveRecord::Migration[8.1]
  def change
    create_table :task_list_transfers do |t|
      t.references :task_list,       null: false, foreign_key: true
      t.references :from_account,    null: false, foreign_key: { to_table: :accounts }
      t.references :to_account,      null: false, foreign_key: { to_table: :accounts }
      t.references :transferred_by,  null: false, foreign_key: { to_table: :users }
      t.string  :token,  null: false
      t.integer :status, null: false, default: 0
      t.timestamps
    end
    add_index :task_list_transfers, :token, unique: true
    add_index :task_list_transfers, :status
  end
end
