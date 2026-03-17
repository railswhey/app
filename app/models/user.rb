# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :memberships, dependent: :destroy, class_name: "Account::Membership"
  has_many :accounts, through: :memberships

  has_many :task_lists, through: :accounts

  has_one :ownership, -> { owner }, inverse_of: :user, dependent: nil, class_name: "Account::Membership"
  has_one :account, through: :ownership
  has_one :inbox, through: :account

  has_one :token, dependent: :destroy

  has_many :notifications,       dependent: :destroy
  has_many :comments,            dependent: :destroy, class_name: "Task::Comment"
  has_many :sent_invitations,    foreign_key: :invited_by_id, dependent: :destroy,  class_name: "Account::Invitation"
  has_many :assigned_task_items, foreign_key: :assigned_user_id,  dependent: :nullify, class_name: "Task::Item"
  has_many :initiated_transfers, foreign_key: :transferred_by_id, dependent: :destroy, class_name: "Task::List::Transfer"

  with_options presence: true do
    validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true

    validates :username, uniqueness: true,
                         length: { in: 3..30 },
                         format: { with: /\A[a-zA-Z0-9_]+\z/, message: "only allows letters, numbers, and underscores" }

    validates :password, confirmation: true, length: { minimum: 8 }, if: -> { new_record? || password.present? }
  end

  normalizes :email, with: -> { _1.strip.downcase }
  normalizes :username, with: -> { _1.strip.downcase }

  generates_token_for(:reset_password, expires_in: 15.minutes) { password_salt&.last(10) }
  generates_token_for(:email_confirmation, expires_in: 24.hours) { email }

  after_create do
    account = Account.create!(uuid: SecureRandom.uuid, name: "#{email.split("@").first}'s workspace", personal: true)

    account.add_member(self, role: :owner)

    account.task_lists.inbox.create!

    create_token!
  end

  after_create_commit do
    UserMailer.with(user: self, token: generate_token_for(:email_confirmation)).email_confirmation.deliver_later
  end

  before_destroy prepend: true do
    account.destroy!
  end

  def self.find_by_reset_password_token(token)
    find_by_token_for(:reset_password, token)
  end

  def self.send_reset_password_email(email)
    user = find_by(email: email)

    return unless user

    UserMailer.with(user: user, token: user.generate_token_for(:reset_password)).reset_password.deliver_later
  end

  def initials
    username = username.to_s

    return username[0, 2].upcase if username.present?

    email = email.to_s

    parts = email.split("@").first.to_s.split(/[._-]/)

    parts.size >= 2 ? "#{parts[0][0]}#{parts[1][0]}".upcase : email[0, 2].upcase
  end
end
