# frozen_string_literal: true

class Task::List::Stats
  Result = Data.define(:total, :done, :pending, :pct, :assigned, :comments_count,
                       :last_activity, :preview_items, :list_comments)

  attr_reader :task_list

  def initialize(task_list)
    @task_list = task_list
  end

  def call
    total = task_items.count
    done  = task_items.completed.count

    Result.new(
      total:,
      done:,
      pending:        total - done,
      pct:            total > 0 ? (done * 100.0 / total).round : 0,
      assigned:       task_items.where.not(assigned_user_id: nil).count,
      comments_count: comments.count,
      last_activity:  task_items.order(updated_at: :desc).pick(:updated_at) || task_list.created_at,
      preview_items:  task_items.incomplete.order(created_at: :desc).limit(5).includes(:assigned_user),
      list_comments:  comments.chronological.includes(:user)
    )
  end

  private

  def task_items = task_list.task_items
  def comments = task_list.comments
end
