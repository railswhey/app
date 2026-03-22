class AddNamePersonalToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :name, :string
    add_column :accounts, :personal, :boolean, default: false, null: false
  end
end
