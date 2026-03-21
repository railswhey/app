# frozen_string_literal: true

module Account::Teardown
  def self.call(uuid:)
    person = Account::Person.find_by!(uuid:)

    person.ownership.account.destroy!

    person.destroy!
  end
end
