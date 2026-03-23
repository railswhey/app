# frozen_string_literal: true

class API::V1::Task::Item::BaseController < API::V1::BaseController
  rescue_from ActiveRecord::RecordNotFound do
    render_json_with_failure(status: :not_found, message: "Task list or item not found")
  end

  private

  def require_task_list!
    raise ActiveRecord::RecordNotFound unless current.task_list
  end

  def set_task_item
    @task_item = current.tasks.find(params[:id])
    @task_list = current.task_list
  end
end
