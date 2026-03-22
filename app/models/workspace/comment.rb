# frozen_string_literal: true

class Workspace::Comment < Abstract::Workspace
  belongs_to :commentable, polymorphic: true
  belongs_to :member

  validates :body, presence: true

  normalizes :body, with: -> { it.strip }

  scope :chronological, -> { order(created_at: :asc) }
  scope :search,        -> { where("body LIKE ?", "%#{it}%") }
  scope :for, ->(workspace:) {
    where(commentable_type: "Workspace::Task", commentable_id: workspace.tasks.select(:id))
    .or(where(commentable_type: "Workspace::List", commentable_id: workspace.lists.select(:id)))
  }

  def authored_by?(member)
    member_id == member.id
  end
end
