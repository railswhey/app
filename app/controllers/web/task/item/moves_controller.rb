# frozen_string_literal: true

class Web::Task::Item::MovesController < Web::Task::Item::BaseController
  before_action :authenticate_user!
  before_action :set_task_item

  def create
    target_list = Current.account.task_lists.find_by(id: params[:target_list_id])

    unless @task_item.movable_to?(target_list)
      message = target_list ? "Task is already in that list." : "Target list not found."
      redirect_to task_list_items_path(@task_list), alert: message
      return
    end

    @task_item.update!(list: target_list)

    redirect_to task_list_items_path(@task_list), notice: "\"#{@task_item.name}\" moved to \"#{target_list.name}\"."
  end

  private

  def set_task_item
    @task_item = Current.task_items.find(params[:task_item_id])
    @task_list = Current.task_list
  end
end
