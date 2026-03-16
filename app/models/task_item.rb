# frozen_string_literal: true

class TaskItem < ApplicationRecord
  belongs_to :task_list
  belongs_to :assigned_user, class_name: "User", optional: true

  has_many :comments, as: :commentable, dependent: :destroy

  scope :completed,    -> { where.not(completed_at: nil) }
  scope :incomplete,   -> { where(completed_at: nil) }
  scope :assigned_to,  ->(user_id) { where(assigned_user_id: user_id) }
  scope :search,       ->(q) { where("task_items.name LIKE ? OR task_items.description LIKE ?", "%#{q}%", "%#{q}%") }
  scope :for_account, ->(account_id) { joins(:task_list).where(task_lists: { account_id: account_id }) }
  scope :assignment_filter_by, ->(value) {
    case value
    when "completed"  then completed
    when "incomplete" then incomplete
    else all
    end
  }
  scope :filter_by, ->(value) {
    case value
    when "completed" then completed.order(completed_at: :desc)
    when "incomplete" then incomplete.order(created_at: :desc)
    else order(Arel.sql("task_items.completed_at DESC NULLS FIRST, task_items.created_at DESC"))
    end
  }

  validates :name, presence: true

  attribute :completed, :boolean

  normalizes(:name, with: -> { _1.strip })
  normalizes(:description, with: -> { _1.strip })

  before_validation do
    self.completed_at = completed ? Time.current : nil
  end

  after_initialize do
    self.completed = completed?
  end

  def completed?
    completed_at.present?
  end

  def incomplete?
    !completed?
  end

  def complete!
    self.completed = true

    save!
  end

  def incomplete!
    self.completed = false

    save!
  end

  def movable_to?(target_list)
    target_list.present? && target_list != task_list
  end
end
