# frozen_string_literal: true

class Account < ApplicationRecord
  has_many :memberships,        dependent: :destroy
  has_many :users,              through: :memberships
  has_many :task_lists,         dependent: :destroy, class_name: "Task::List"
  has_many :task_items,         through: :task_lists, source: :items
  has_many :invitations,        dependent: :destroy
  has_many :outgoing_transfers, foreign_key: :from_account_id, dependent: :destroy, class_name: "Task::List::Transfer"
  has_many :incoming_transfers, foreign_key: :to_account_id,   dependent: :destroy, class_name: "Task::List::Transfer"

  has_one :inbox,     -> { inbox }, inverse_of: :account, dependent: nil, class_name: "Task::List"
  has_one :ownership, -> { owner }, inverse_of: :account, dependent: nil, class_name: "Account::Membership"
  has_one :owner, through: :ownership, source: :user

  validates :name, presence: true
  validates :uuid, presence: true, format: /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/

  normalizes :name, with: -> { it.strip }

  def member?(user)           = memberships.granted_to?(user)
  def add_member(user, role:) = memberships.grant(user, role:)
  def owner_or_admin?(user)   = memberships.owner_or_admin?(user)

  def search(query)
    Search.new(self).by(query)
  end
end
