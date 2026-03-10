# frozen_string_literal: true

class Account < ApplicationRecord
  has_many :memberships,        dependent: :destroy
  has_many :users,              through: :memberships
  has_many :task_lists,         dependent: :destroy
  has_many :invitations,        dependent: :destroy
  has_many :outgoing_transfers, class_name: "TaskListTransfer", foreign_key: :from_account_id, dependent: :destroy
  has_many :incoming_transfers, class_name: "TaskListTransfer", foreign_key: :to_account_id,   dependent: :destroy

  has_one :ownership, -> { owner }, class_name: "Membership", inverse_of: :account, dependent: nil
  has_one :inbox,     -> { inbox }, class_name: "TaskList",   inverse_of: :account, dependent: nil
  has_one :owner, through: :ownership, source: :user

  validates :name, presence: true
  validates :uuid, presence: true, format: /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/

  normalizes :name, with: -> { _1.strip }
end
