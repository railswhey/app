# frozen_string_literal: true

class ReplaceUserWithPersonInAccountMemberships < ActiveRecord::Migration[8.1]
  def change
    add_reference :account_memberships, :person, null: false, foreign_key: { to_table: :account_people }

    reversible do |dir|
      dir.up do
        remove_index :account_memberships, name: :index_account_memberships_on_account_id_and_user_id, if_exists: true
      end
    end

    remove_column :account_memberships, :user_id, :integer
    add_index :account_memberships, [ :account_id, :person_id ], unique: true
  end
end
