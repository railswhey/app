# frozen_string_literal: true

class TaskList < ApplicationRecord
  belongs_to :account

  has_many :task_items, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy

  scope :inbox, -> { where(inbox: true) }
  scope :search, ->(q) { where("task_lists.name LIKE ? OR task_lists.description LIKE ?", "%#{q}%", "%#{q}%") }

  Stats = Data.define(:total, :done, :pending, :pct, :assigned, :comments_count,
                      :last_activity, :preview_items, :list_comments)

  validates :name, presence: true

  before_validation :set_inbox_name, if: :inbox?

  normalizes(:name, with: -> { _1.strip })
  normalizes(:description, with: -> { _1.strip })

  def normal?
    !inbox?
  end

  def stats
    items = task_items
    total = items.count
    done  = items.completed.count

    Stats.new(
      total:,
      done:,
      pending:        total - done,
      pct:            total > 0 ? (done * 100.0 / total).round : 0,
      assigned:       items.where.not(assigned_user_id: nil).count,
      comments_count: comments.count,
      last_activity:  items.order(updated_at: :desc).pick(:updated_at) || created_at,
      preview_items:  items.incomplete.order(created_at: :desc).limit(5).includes(:assigned_user),
      list_comments:  comments.chronological.includes(:user)
    )
  end

  private

  def set_inbox_name
    self.name = "Inbox"
    self.description = "This is your default list, it cannot be deleted."
  end
end
