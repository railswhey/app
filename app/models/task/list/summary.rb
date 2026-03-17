# frozen_string_literal: true

module Task::List::Summary
  Result = Data.define(:total, :done, :pending, :completion, :assigned, :comments_count,
                       :last_activity, :preview_items, :list_comments)

  def self.of(list)
    comments = list.comments
    items = list.items
    total = items.count
    done  = items.completed.count

    Result.new(
      total:,
      done:,
      pending:        total - done,
      assigned:       items.where.not(assigned_user_id: nil).count,
      completion:     total > 0 ? (done * 100.0 / total).round : 0,
      last_activity:  items.order(updated_at: :desc).pick(:updated_at) || list.created_at,
      preview_items:  items.incomplete.order(created_at: :desc).limit(5).includes(:assigned_user),
      list_comments:  comments.chronological.includes(:user),
      comments_count: comments.count
    )
  end
end
