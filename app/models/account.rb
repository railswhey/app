# frozen_string_literal: true

class Account < ApplicationRecord
  has_many :memberships, class_name: "Account::Membership", dependent: :destroy
  has_many :users,              through: :memberships
  has_many :task_lists,         class_name: "Task::List", dependent: :destroy
  has_many :invitations,        class_name: "Account::Invitation", dependent: :destroy
  has_many :outgoing_transfers, class_name: "Task::List::Transfer", foreign_key: :from_account_id, dependent: :destroy
  has_many :incoming_transfers, class_name: "Task::List::Transfer", foreign_key: :to_account_id,   dependent: :destroy

  has_one :ownership, -> { owner }, class_name: "Account::Membership", inverse_of: :account, dependent: nil
  has_one :inbox,     -> { inbox }, class_name: "Task::List",          inverse_of: :account, dependent: nil
  has_one :owner, through: :ownership, source: :user

  validates :name, presence: true
  validates :uuid, presence: true, format: /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/

  normalizes :name, with: -> { it.strip }

  def owner_or_admin?(user)
    memberships.owner_or_admin.exists?(user: user)
  end

  def member?(user)
    memberships.exists?(user: user)
  end

  def add_member(user, role:)
    memberships.find_or_create_by!(user: user) { it.role = role }
  end

  def search(query)
    Account::Search.new(self).with(query.to_s.strip)
  end
end
