# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  scope :unread,        -> { where(read_at: nil) }
  scope :read,          -> { where.not(read_at: nil) }
  scope :chronological, -> { order(created_at: :desc) }

  validates :action, presence: true

  def read?   = read_at.present?
  def unread? = read_at.nil?

  def mark_read!
    update_column(:read_at, Time.current) if unread?
  end
end
