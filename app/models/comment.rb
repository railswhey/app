# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :user

  validates :body, presence: true

  normalizes :body, with: -> { _1.strip }

  scope :chronological, -> { order(created_at: :asc) }
  scope :search, ->(q) { where("body LIKE ?", "%#{q}%") }

  # Returns comments visible to a given account (across both commentable types).
  def self.for_account(account_id)
    task_item_ids = TaskItem.joins(:task_list).where(task_lists: { account_id: }).ids
    task_list_ids = TaskList.where(account_id:).ids

    where(
      "(commentable_type = 'TaskItem' AND commentable_id IN (?)) OR " \
      "(commentable_type = 'TaskList' AND commentable_id IN (?))",
      task_item_ids.presence || [ 0 ],
      task_list_ids.presence || [ 0 ]
    )
  end
end
