# frozen_string_literal: true

class Web::Task::Item::AssignmentsController < Web::BaseController
  before_action :authenticate_user!

  def index
    @filter = params[:filter]
    items = TaskItem.for_account(Current.account_id).assigned_to(Current.user.id)

    @task_items = items.assignment_filter_by(@filter)
      .order(created_at: :desc).limit(100).includes(:task_list)

    @item_counts = {
      all:        items.count,
      incomplete: items.incomplete.count,
      completed:  items.completed.count
    }
  end
end
