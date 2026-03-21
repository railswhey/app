# frozen_string_literal: true

class ReplaceInvitedByUserWithPersonInAccountInvitations < ActiveRecord::Migration[8.1]
  def change
    add_reference :account_invitations, :invited_by_person, null: true, foreign_key: { to_table: :account_people }

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE account_invitations
          SET invited_by_person_id = (
            SELECT account_people.id
            FROM account_people
            JOIN users ON users.uuid = account_people.uuid
            WHERE users.id = account_invitations.invited_by_id
          )
        SQL
      end
    end

    change_column_null :account_invitations, :invited_by_person_id, false
    remove_reference :account_invitations, :invited_by, foreign_key: { to_table: :users }
    rename_column :account_invitations, :invited_by_person_id, :invited_by_id
  end
end
