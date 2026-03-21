# frozen_string_literal: true

class Web::Task::Item::AssignmentsController < Web::BaseController
  before_action :authenticate_user!

  def index
    items = Current.workspace.tasks.assigned_to(Current.workspace.member.id)

    @filter = params[:filter]

    @task_items = items.assignment_filter_by(@filter).order(created_at: :desc).limit(100).includes(:list)

    @item_counts = {
      all:        items.count,
      incomplete: items.incomplete.count,
      completed:  items.completed.count
    }
  end
end
