# frozen_string_literal: true

class Task::List::Stats
  Result = Data.define(:total, :done, :pending, :pct, :assigned, :comments_count,
                       :last_activity, :preview_items, :list_comments)

  attr_reader :list

  def initialize(list)
    @list = list
  end

  def call
    total = items.count
    done  = items.completed.count

    Result.new(
      total:,
      done:,
      pending:        total - done,
      pct:            total > 0 ? (done * 100.0 / total).round : 0,
      assigned:       items.where.not(assigned_user_id: nil).count,
      comments_count: comments.count,
      last_activity:  items.order(updated_at: :desc).pick(:updated_at) || list.created_at,
      preview_items:  items.incomplete.order(created_at: :desc).limit(5).includes(:assigned_user),
      list_comments:  comments.chronological.includes(:user)
    )
  end

  private

  def items = list.items
  def comments = list.comments
end
