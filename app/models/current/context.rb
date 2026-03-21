# frozen_string_literal: true

class Current::Context
  attr_reader :user, :person, :account, :workspace

  def self.empty
    new(user: nil, person: nil, account: nil, workspace: { record: nil, member: nil })
  end

  def initialize(user:, person:, account:, workspace:)
    @user      = user
    @person    = person
    @account   = account
    @workspace = Current::Workspace.new(record: workspace[:record], member: workspace[:member])
  end

  def account_id = account&.id

  def user?           = user.present?
  def account?        = account.present?
  def workspace?      = workspace.present?
  def owner_or_admin? = person && account&.owner_or_admin?(person)

  def authorized?
    user? && account? && workspace?
  end
end
