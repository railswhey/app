# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_one :token, dependent: :destroy

  has_many :notifications, dependent: :destroy

  with_options presence: true do
    validates :email, format: { with: Persona::EMAIL }, uniqueness: true

    validates :username, uniqueness: true,
                         length: { in: 3..30 },
                         format: { with: Persona::USERNAME, message: "only allows letters, numbers, and underscores" }

    validates :password, confirmation: true, length: { minimum: 8 }, if: -> { new_record? || password.present? }
  end

  validates :uuid, presence: true, format: { with: UUID::REGEXP }, uniqueness: true

  normalizes :email, with: -> { it.strip.downcase }
  normalizes :username, with: -> { it.strip.downcase }

  generates_token_for(:reset_password, expires_in: 15.minutes) { password_salt&.last(10) }
  generates_token_for(:email_confirmation, expires_in: 24.hours) { email }

  def initials = Persona.initials(email: email, username: username)
end
