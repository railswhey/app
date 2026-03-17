# frozen_string_literal: true

class Account::Invitation < ApplicationRecord
  belongs_to :account
  belongs_to :invited_by, class_name: "User"

  has_secure_token :token

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :account_id, message: "has already been invited to this account" }

  normalizes :email, with: -> { it.strip.downcase }

  scope :pending,  -> { where(accepted_at: nil) }
  scope :accepted, -> { where.not(accepted_at: nil) }

  def accepted? = accepted_at.present?
  def pending?  = accepted_at.nil?

  def acceptable_by?(user)
    pending? && !account.member?(user)
  end

  def accept!(user) = lifecycle.accept(by: user)

  def lifecycle     = Lifecycle.new(self)
end
