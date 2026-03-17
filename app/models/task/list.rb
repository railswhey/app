# frozen_string_literal: true

class Task::List < ApplicationRecord
  belongs_to :account

  has_many :task_items, class_name: "Task::Item", foreign_key: :task_list_id, dependent: :destroy
  has_many :comments, as: :commentable, class_name: "Task::Comment", dependent: :destroy

  scope :inbox, -> { where(inbox: true) }
  scope :search, ->(q) { where("task_lists.name LIKE ? OR task_lists.description LIKE ?", "%#{q}%", "%#{q}%") }

  validates :name, presence: true

  before_validation :set_inbox_name, if: :inbox?

  normalizes(:name, with: -> { _1.strip })
  normalizes(:description, with: -> { _1.strip })

  def normal?
    !inbox?
  end

  def stats
    Task::List::Stats.new(self).call
  end

  private

  def set_inbox_name
    self.name = "Inbox"
    self.description = "This is your default list, it cannot be deleted."
  end
end
