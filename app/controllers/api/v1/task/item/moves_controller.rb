# frozen_string_literal: true

class API::V1::Task::Item::MovesController < API::V1::BaseController
  before_action :authenticate_user!
  before_action :set_task_item

  rescue_from ActiveRecord::RecordNotFound do
    render_json_with_failure(status: :not_found, message: "Task list or item not found")
  end

  def create
    source_list = @task_list
    target_list = Current.account.task_lists.find_by(id: params[:target_list_id])

    unless target_list
      render_json_with_failure(status: :unprocessable_entity, message: "Target list not found.")
      return
    end

    if target_list == source_list
      render_json_with_failure(status: :unprocessable_entity, message: "Task is already in that list.")
      return
    end

    @task_item.update!(task_list: target_list)

    render "api/v1/task/items/show", status: :ok
  end

  private

  def set_task_item
    @task_item = Current.task_items.find(params[:task_item_id])
    @task_list = Current.task_list
  end
end
