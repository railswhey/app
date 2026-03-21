# frozen_string_literal: true

class Workspace::List < ApplicationRecord
  belongs_to :workspace

  has_many :tasks, foreign_key: :workspace_list_id, dependent: :destroy, class_name: "Workspace::Task"
  has_many :comments, as: :commentable, dependent: :destroy, class_name: "Workspace::Comment"

  scope :inbox, -> { where(inbox: true) }
  scope :search, -> { where("workspace_lists.name LIKE ? OR workspace_lists.description LIKE ?", "%#{it}%", "%#{it}%") }

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
    Summary.of(self)
  end
end
