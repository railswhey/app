# frozen_string_literal: true

class Account::Membership < ApplicationRecord
  OWNER = "owner"
  ADMIN = "admin"
  COLLABORATOR = "collaborator"

  belongs_to :person
  belongs_to :account

  enum :role, { owner: OWNER, admin: ADMIN, collaborator: COLLABORATOR }

  scope :owner_or_admin, -> { where(role: [ OWNER, ADMIN ]) }

  validates :role, presence: true
  validates :person_id, uniqueness: { scope: :account_id }

  def self.owner_or_admin?(person) = owner_or_admin.exists?(person: person)
  def self.granted_to?(person)     = exists?(person: person)
  def self.grant(person, role:)    = find_or_create_by!(person: person) { it.role = role }

  def removable_by?(person)        = !owner? && self.person != person
end
