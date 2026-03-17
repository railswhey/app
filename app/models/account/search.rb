# frozen_string_literal: true

class Account::Search
  Results = Data.define(:task_items, :task_lists, :comments)

  attr_reader :account

  def initialize(account)
    @account = account
  end

  def empty
    Results.new(task_items: Task::Item.none, task_lists: Task::List.none, comments: Task::Comment.none)
  end

  def with(query)
    return empty if query.size <= 1

    Results.new(
      task_items: task_items.search(query).includes(:task_list).order(created_at: :desc).limit(20),
      task_lists: task_lists.search(query).limit(10),
      comments:   comments(query)
    )
  end

  private

  def task_lists = account.task_lists
  def task_items = Task::Item.for_account(account.id)

  def comments(query)
    Task::Comment.where(
      "(commentable_type = 'Task::Item' AND commentable_id IN (?)) OR " \
      "(commentable_type = 'Task::List' AND commentable_id IN (?))",
      task_items.ids.presence || [ 0 ],
      task_lists.ids.presence || [ 0 ]
    ).search(query).includes(:user, :commentable).order(created_at: :desc).limit(10)
  end
end
