# frozen_string_literal: true

class Task::Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :user

  validates :body, presence: true

  normalizes :body, with: -> { _1.strip }

  scope :chronological, -> { order(created_at: :asc) }
  scope :search, ->(q) { where("body LIKE ?", "%#{q}%") }

  def authored_by?(user)
    user_id == user.id
  end
end
