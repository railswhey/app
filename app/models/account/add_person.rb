# frozen_string_literal: true

class Account::AddPerson
  attr_reader :account

  def initialize(account:)
    @account  = account
  end

  def call(uuid:, email:, username:, role: :collaborator)
    person = Account::Person.find_or_create_by!(uuid:) do
      it.email    = email
      it.username = username
    end

    account.add_member(person, role:)

    person
  end
end
