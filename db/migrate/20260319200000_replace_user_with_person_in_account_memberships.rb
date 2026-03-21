# frozen_string_literal: true

class ReplaceUserWithPersonInAccountMemberships < ActiveRecord::Migration[8.1]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO account_people (uuid, email, username, created_at, updated_at)
          SELECT uuid, email, username, created_at, updated_at
          FROM users
          WHERE uuid NOT IN (SELECT uuid FROM account_people)
        SQL
      end
    end

    add_reference :account_memberships, :person, null: true, foreign_key: { to_table: :account_people }

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE account_memberships
          SET person_id = (
            SELECT account_people.id
            FROM account_people
            JOIN users ON users.uuid = account_people.uuid
            WHERE users.id = account_memberships.user_id
          )
        SQL
      end
    end

    change_column_null :account_memberships, :person_id, false

    reversible do |dir|
      dir.up do
        remove_index :account_memberships, name: :index_account_memberships_on_account_id_and_user_id, if_exists: true
      end
    end

    remove_reference :account_memberships, :user, foreign_key: true
    add_index :account_memberships, [ :account_id, :person_id ], unique: true
  end
end
