# frozen_string_literal: true

class Account::Invitation < Abstract::Account
  belongs_to :account
  belongs_to :invited_by, class_name: "Person"

  has_secure_token :token

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :account_id, message: "has already been invited to this account" }

  normalizes :email, with: -> { it.strip.downcase }

  scope :pending,  -> { where(accepted_at: nil) }
  scope :accepted, -> { where.not(accepted_at: nil) }

  def accepted? = accepted_at.present?
  def pending?  = accepted_at.nil?

  def acceptable_by?(user)
    person = Account::Person.find_by(uuid: user.uuid)

    pending? && (person.nil? || !account.member?(person))
  end

  def accept!
    return false if accepted?

    update_column(:accepted_at, Time.current)
  end

  def revert!
    update_column(:accepted_at, nil)
  end
end
