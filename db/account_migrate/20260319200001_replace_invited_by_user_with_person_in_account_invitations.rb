# frozen_string_literal: true

class ReplaceInvitedByUserWithPersonInAccountInvitations < ActiveRecord::Migration[8.1]
  def change
    remove_column :account_invitations, :invited_by_id, :integer
    add_reference :account_invitations, :invited_by, null: false, foreign_key: { to_table: :account_people }
  end
end
