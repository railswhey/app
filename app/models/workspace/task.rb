# frozen_string_literal: true

class Workspace::Task < Abstract::Workspace
  COMPLETED  = "completed"
  INCOMPLETE = "incomplete"

  belongs_to :list, foreign_key: :workspace_list_id
  belongs_to :assigned_member, optional: true, class_name: "Member"

  has_many :comments, as: :commentable, dependent: :destroy

  scope :completed,   -> { where.not(completed_at: nil) }
  scope :incomplete,  -> { where(completed_at: nil) }
  scope :assigned_to, -> { where(assigned_member_id: it) }
  scope :search,      -> { where("workspace_tasks.name LIKE ? OR workspace_tasks.description LIKE ?", "%#{it}%", "%#{it}%") }
  scope :assignment_filter_by, ->(value) {
    case value
    when COMPLETED  then completed
    when INCOMPLETE then incomplete
    else all
    end
  }
  scope :filter_by, ->(value) {
    case value
    when COMPLETED  then completed.order(completed_at: :desc)
    when INCOMPLETE then incomplete.order(created_at: :desc)
    else order(Arel.sql("workspace_tasks.completed_at DESC NULLS FIRST, workspace_tasks.created_at DESC"))
    end
  }

  validates :name, presence: true

  attribute :completed, :boolean

  normalizes(:name, with: -> { it.strip })
  normalizes(:description, with: -> { it.strip })

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
    completed? ? COMPLETED : INCOMPLETE
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
    target_list.present? && target_list != list
  end
end
