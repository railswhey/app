# frozen_string_literal: true

class API::V1::Task::Item::MovesController < API::V1::Task::Item::BaseController
  before_action :authenticate_user!
  before_action :set_task_item

  def create
    target_list = Current.account.task_lists.find_by(id: params[:target_list_id])

    unless @task_item.movable_to?(target_list)
      message = target_list ? "Task is already in that list." : "Target list not found."
      render_json_with_failure(status: :unprocessable_entity, message: message)
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
