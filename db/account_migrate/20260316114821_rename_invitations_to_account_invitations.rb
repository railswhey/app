class RenameInvitationsToAccountInvitations < ActiveRecord::Migration[8.1]
  def change
    rename_table :invitations, :account_invitations
  end
end
