# frozen_string_literal: true

class Task::Item < ApplicationRecord
  belongs_to :task_list, class_name: "Task::List"
  belongs_to :assigned_user, optional: true, class_name: "User"

  has_many :comments, as: :commentable, dependent: :destroy, class_name: "Task::Comment"

  scope :completed,   -> { where.not(completed_at: nil) }
  scope :incomplete,  -> { where(completed_at: nil) }
  scope :assigned_to, -> { where(assigned_user_id: it) }
  scope :search,      -> { where("task_items.name LIKE ? OR task_items.description LIKE ?", "%#{it}%", "%#{it}%") }
  scope :assignment_filter_by, ->(value) {
    case value
    when Task::COMPLETED  then completed
    when Task::INCOMPLETE then incomplete
    else all
    end
  }
  scope :filter_by, ->(value) {
    case value
    when Task::COMPLETED  then completed.order(completed_at: :desc)
    when Task::INCOMPLETE then incomplete.order(created_at: :desc)
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

  def status
    completed? ? Task::COMPLETED : Task::INCOMPLETE
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
