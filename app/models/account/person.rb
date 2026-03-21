# frozen_string_literal: true

class Account::Person < ApplicationRecord
  has_many :memberships, dependent: :destroy, foreign_key: :person_id
  has_many :accounts, through: :memberships

  has_one :ownership, -> { owner }, foreign_key: :person_id, class_name: "Membership"

  validates :uuid,     presence: true, format: { with: UUID::REGEXP }, uniqueness: true
  validates :username, presence: true, format: { with: Persona::USERNAME }
  validates :email,    presence: true, format: { with: Persona::EMAIL }

  def initials = Persona.initials(email: email, username: username)
end
