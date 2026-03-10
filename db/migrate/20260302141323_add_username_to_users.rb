class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :username, :string

    # Backfill existing users with username derived from email
    execute <<~SQL
      UPDATE users SET username = LOWER(REPLACE(SUBSTR(email, 1, INSTR(email, '@') - 1), '.', '_'))
    SQL

    change_column_null :users, :username, false
    add_index :users, :username, unique: true
  end

  def down
    remove_column :users, :username
  end
end
