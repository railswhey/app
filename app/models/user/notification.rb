# frozen_string_literal: true

class User::Notification < ApplicationRecord
  UNREAD = "unread"
  INVITES = "invites"
  TRANSFERS = "transfers"

  ACTIONS = [
    INVITATION_RECEIVED = "invitation_received",
    INVITATION_ACCEPTED = "invitation_accepted",
    TRANSFER_REQUESTED  = "transfer_requested",
    TRANSFER_ACCEPTED   = "transfer_accepted",
    TRANSFER_REJECTED   = "transfer_rejected"
  ].freeze

  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  enum :action, ACTIONS.to_h { [ it, it ] }

  scope :read,          -> { where.not(read_at: nil) }
  scope :unread,        -> { where(read_at: nil) }
  scope :chronological, -> { order(created_at: :desc) }
  scope :filter_by, ->(type) {
    case type
    when UNREAD    then unread
    when INVITES   then where(action: [ INVITATION_RECEIVED, INVITATION_ACCEPTED ])
    when TRANSFERS then where(action: [ TRANSFER_REQUESTED, TRANSFER_ACCEPTED, TRANSFER_REJECTED ])
    else all
    end
  }

  validates :action, presence: true

  def read?   = read_at.present?
  def unread? = read_at.nil?

  def mark_read!
    update_column(:read_at, Time.current) if unread?
  end
end
