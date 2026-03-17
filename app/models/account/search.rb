# frozen_string_literal: true

class Account::Search
  Results = Data.define(:task_lists, :task_items, :comments)

  attr_reader :account

  def initialize(account)
    @account = account
  end

  def empty
    Results.new(task_lists: Task::List.none, task_items: Task::Item.none, comments: Task::Comment.none)
  end

  def with(query)
    return empty if query.size <= 1

    Results.new(
      task_lists: account.task_lists.search(query).limit(10),
      task_items: account.task_items.search(query).includes(:list).order(created_at: :desc).limit(20),
      comments:   Task::Comment.for_account(account).search(query).includes(:user, :commentable).order(created_at: :desc).limit(10)
    )
  end
end
