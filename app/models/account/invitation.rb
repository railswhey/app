# frozen_string_literal: true

class Account::Invitation < ApplicationRecord
  belongs_to :account
  belongs_to :invited_by, class_name: "User"

  has_secure_token :token

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :account_id, message: "has already been invited to this account" }

  normalizes :email, with: -> { _1.strip.downcase }

  scope :pending,  -> { where(accepted_at: nil) }
  scope :accepted, -> { where.not(accepted_at: nil) }

  after_create_commit :send_invite_email
  after_create_commit :notify_existing_invitee

  def accepted? = accepted_at.present?
  def pending?  = accepted_at.nil?

  def acceptable_by?(user)
    pending? && !account.member?(user)
  end

  def accept!(user)
    return false if accepted?

    transaction do
      account.add_member(user, role: :collaborator)

      update_column(:accepted_at, Time.current)

      User::Notification.create!(user: invited_by, notifiable: self, action: User::Notification::INVITATION_ACCEPTED)
    end

    true
  end

  private

  def send_invite_email
    Account::InvitationMailer.invite(self).deliver_later
  end

  def notify_existing_invitee
    invitee = User.find_by(email:)

    return unless invitee

    User::Notification.create!(user: invitee, notifiable: self, action: User::Notification::INVITATION_RECEIVED)
  end
end
