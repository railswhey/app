# frozen_string_literal: true

class API::V1::Task::Item::CompleteController < API::V1::BaseController
  before_action :authenticate_user!
  before_action :set_task_item

  rescue_from ActiveRecord::RecordNotFound do
    render_json_with_failure(status: :not_found, message: "Task list or item not found")
  end

  def update
    @task_item.complete!

    render "api/v1/task/items/show", status: :ok, location: api_v1_task_list_item_url(Current.task_list_id, @task_item)
  end

  private

  def require_task_list!
    raise ActiveRecord::RecordNotFound unless Current.task_list_id
  end

  def set_task_item
    @task_item = Current.task_items.find(params[:id])
    @task_list = Current.task_list
  end
end
