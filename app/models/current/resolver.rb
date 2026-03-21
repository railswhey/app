# frozen_string_literal: true

module Current::Resolver
  extend self

  def call(user_id: nil, user_token: nil, account_id: nil)
    user = user(id: user_id, token: user_token)

    return Current::Context.empty unless user

    person, account = person_and_account(id: account_id, user:)

    member    = ::Workspace::Member.find_by(uuid: user.uuid)
    workspace = account && ::Workspace.find_by(uuid: account.uuid)

    Current::Context.new(user:, person:, account:, workspace: { member:, record: workspace })
  end

  def user(id:, token:)
    return User.find_by(id: id) if id

    return unless token

    short, long = User::Token::Secret.parse(token)

    checksum = User::Token::Secret.checksum(short:, long:)

    User.joins(:token).find_by(user_tokens: { short:, checksum: })
  end

  private

  def person_and_account(id:, user:)
    person = Account::Person.find_by(uuid: user.uuid)

    return unless person

    membership = id ? person.memberships.find_by(account_id: id) : (person.ownership || person.memberships.first)

    [ person, membership&.account ]
  end
end
