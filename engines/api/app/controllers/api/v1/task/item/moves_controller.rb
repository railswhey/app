# frozen_string_literal: true

class API::V1::Task::Item::MovesController < API::V1::Task::Item::BaseController
  before_action :authenticate_user!
  before_action :set_task_item_from_param

  def create
    target_list = current.task_lists.find_by(id: params[:target_list_id])

    unless @task_item.movable_to?(target_list)
      message = target_list ? "Task is already in that list." : "Target list not found."

      return render_json_with_failure(status: :unprocessable_entity, message: message)
    end

    @task_item.update!(list: target_list)

    render "task/items/show", status: :ok
  end

  private

  def set_task_item_from_param
    @task_item = current.tasks.find(params[:task_item_id])
    @task_list = current.task_list
  end
end
