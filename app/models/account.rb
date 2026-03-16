# frozen_string_literal: true

class Account < ApplicationRecord
  has_many :memberships,        dependent: :destroy
  has_many :users,              through: :memberships
  has_many :task_lists,         dependent: :destroy
  has_many :invitations,        dependent: :destroy
  has_many :outgoing_transfers, class_name: "TaskListTransfer", foreign_key: :from_account_id, dependent: :destroy
  has_many :incoming_transfers, class_name: "TaskListTransfer", foreign_key: :to_account_id,   dependent: :destroy

  has_one :ownership, -> { owner }, class_name: "Membership", inverse_of: :account, dependent: nil
  has_one :inbox,     -> { inbox }, class_name: "TaskList",   inverse_of: :account, dependent: nil
  has_one :owner, through: :ownership, source: :user

  validates :name, presence: true
  validates :uuid, presence: true, format: /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/

  normalizes :name, with: -> { _1.strip }

  SearchResults = Data.define(:task_items, :task_lists, :comments)

  def owner_or_admin?(user)
    memberships.owner_or_admin.exists?(user: user)
  end

  def search(query)
    query = query.to_s.strip

    if query.length < 2
      return SearchResults.new(task_items: TaskItem.none, task_lists: TaskList.none, comments: Comment.none)
    end

    SearchResults.new(
      task_items: TaskItem.joins(:task_list).where(task_lists: { account_id: id })
                    .search(query).includes(:task_list).order(created_at: :desc).limit(20),
      task_lists: task_lists.search(query).limit(10),
      comments:   Comment.for_account(id).search(query)
                    .includes(:user, :commentable).order(created_at: :desc).limit(10)
    )
  end
end
