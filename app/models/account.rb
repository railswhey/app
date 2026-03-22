# frozen_string_literal: true

class Account < Abstract::Account
  has_many :memberships,  dependent: :destroy
  has_many :people,       through: :memberships, source: :person
  has_many :invitations,  dependent: :destroy

  has_one :ownership, -> { owner }, inverse_of: :account, dependent: nil, class_name: "Membership"
  has_one :owner, through: :ownership, source: :person

  validates :name, presence: true
  validates :uuid, presence: true, format: { with: UUID::REGEXP }

  normalizes :name, with: -> { it.strip }

  def member?(person)           = memberships.granted_to?(person)
  def add_member(person, role:) = memberships.grant(person, role:)
  def owner_or_admin?(person)   = memberships.owner_or_admin?(person)
end
