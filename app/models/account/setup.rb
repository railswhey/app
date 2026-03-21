# frozen_string_literal: true

class Account::Setup
  def self.call(uuid:, email:, username:)
    person = Account::Person.create!(uuid: uuid, email: email, username: username)

    account = Account.create!(
      uuid: uuid,
      name: "#{email.split("@").first}'s workspace",
      personal: true
    )

    account.add_member(person, role: :owner)

    account
  end
end
