# frozen_string_literal: true

class Task::Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :user

  validates :body, presence: true

  normalizes :body, with: -> { it.strip }

  scope :search,        -> { where("body LIKE ?", "%#{it}%") }
  scope :chronological, -> { order(created_at: :asc) }
  scope :for_account,   ->(account) {
    where(commentable_type: "Task::Item", commentable_id: account.task_items.select(:id))
    .or(where(commentable_type: "Task::List", commentable_id: account.task_lists.select(:id)))
  }

  def authored_by?(user)
    user_id == user.id
  end
end
