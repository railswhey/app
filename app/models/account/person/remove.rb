# frozen_string_literal: true

module Account::Person::Remove
  def self.call(uuid:, account:)
    person = Account::Person.find_by(uuid:)

    return unless person

    Account.transaction do
      account.memberships.where(person:).destroy_all

      person.destroy! if person.memberships.none?
    end
  end
end
