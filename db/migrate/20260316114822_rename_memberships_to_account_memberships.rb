class RenameMembershipsToAccountMemberships < ActiveRecord::Migration[8.1]
  def change
    rename_table :memberships, :account_memberships
  end
end
