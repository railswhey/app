# frozen_string_literal: true

class API::V1::Task::Item::AssignmentsController < API::V1::BaseController
  before_action :authenticate_user!

  def index
    items = current.workspace.tasks.assigned_to(current.workspace.member.id)

    @filter = params[:filter]

    @task_items = items.assignment_filter_by(@filter).order(created_at: :desc).limit(100).includes(:list)

    @item_counts = {
      all:        items.count,
      incomplete: items.incomplete.count,
      completed:  items.completed.count
    }
  end
end
