# frozen_string_literal: true

module Account::Workspace
  def self.for(owner)
    Account.transaction { for!(owner) }
  end

  def self.for!(owner)
    account = Account.create!(
      uuid: SecureRandom.uuid,
      name: "#{owner.email.split("@").first}'s workspace",
      personal: true
    )

    account.add_member(owner, role: :owner)
    account.task_lists.inbox.create!

    account
  end
end
