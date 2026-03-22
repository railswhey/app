class CreateAccountPeople < ActiveRecord::Migration[8.1]
  def change
    create_table :account_people do |t|
      t.string :uuid, null: false
      t.string :email
      t.string :username

      t.timestamps
    end
    add_index :account_people, :uuid, unique: true
  end
end
