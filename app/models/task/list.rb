# frozen_string_literal: true

class Task::List < ApplicationRecord
  belongs_to :account

  has_many :items, foreign_key: :task_list_id, dependent: :destroy, class_name: "Task::Item"
  has_many :comments, as: :commentable, dependent: :destroy, class_name: "Task::Comment"

  scope :inbox, -> { where(inbox: true) }
  scope :search, -> { where("task_lists.name LIKE ? OR task_lists.description LIKE ?", "%#{it}%", "%#{it}%") }

  validates :name, presence: true

  before_validation(if: :inbox?) do
    it.name = "Inbox"
    it.description = "This is your default list, it cannot be deleted."
  end

  normalizes(:name, with: -> { it.strip })
  normalizes(:description, with: -> { it.strip })

  def normal?
    !inbox?
  end

  def stats
    Task::List::Stats.new(self).call
  end
end
