# frozen_string_literal: true

class Account::Membership < ApplicationRecord
  OWNER = "owner"
  ADMIN = "admin"
  COLLABORATOR = "collaborator"

  belongs_to :user
  belongs_to :account

  enum :role, { owner: OWNER, admin: ADMIN, collaborator: COLLABORATOR }

  scope :owner_or_admin, -> { where(role: [ OWNER, ADMIN ]) }

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :account_id }

  def self.owner_or_admin?(user) = owner_or_admin.exists?(user: user)
  def self.granted_to?(user)     = exists?(user: user)
  def self.grant(user, role:)    = find_or_create_by!(user: user) { it.role = role }

  def removable_by?(user)        = !owner? && self.user != user
end
