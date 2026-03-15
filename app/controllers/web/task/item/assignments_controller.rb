# frozen_string_literal: true

class Web::Task::Item::AssignmentsController < Web::BaseController
  before_action :authenticate_user!

  def index
    @filter = params[:filter]
    items = TaskItem
      .joins(:task_list)
      .where(task_lists: { account_id: Current.account_id })
      .where(assigned_user_id: Current.user.id)

    @task_items = case @filter
    when "completed"  then items.completed
    when "incomplete" then items.incomplete
    else items
    end.order(created_at: :desc).limit(100).includes(:task_list)

    @item_counts = {
      all:        items.count,
      incomplete: items.incomplete.count,
      completed:  items.completed.count
    }
  end
end
