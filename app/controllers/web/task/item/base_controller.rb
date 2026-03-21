# frozen_string_literal: true

class Web::Task::Item::BaseController < Web::BaseController
  private

  def require_task_list!
    raise ActiveRecord::RecordNotFound unless Current.task_list
  end

  def set_task_item
    @task_item = Current.tasks.find(params[:id])
    @task_list = Current.task_list
  end

  def task_items_url(...)
    task_list_items_url(Current.task_list_id, ...)
  end

  def task_item_url(...)
    task_list_item_url(Current.task_list_id, ...)
  end

  def next_location
    return task_item_assignments_url if params[:return_to] == "task_item_assignments"
    case params[:filter]
    when Workspace::Task::COMPLETED  then task_items_url(filter: Workspace::Task::COMPLETED)
    when Workspace::Task::INCOMPLETE then task_items_url(filter: Workspace::Task::INCOMPLETE)
    when "show" then task_item_url(@task_item)
    else task_items_url
    end
  end
end
