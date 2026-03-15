# frozen_string_literal: true

class Web::Task::Item::MovesController < Web::Task::Item::BaseController
  before_action :authenticate_user!
  before_action :set_task_item

  def create
    source_list = @task_list
    target_list = Current.account.task_lists.find_by(id: params[:target_list_id])

    unless target_list
      redirect_to task_list_items_path(source_list), alert: "Target list not found."
      return
    end

    if target_list == source_list
      redirect_to task_list_items_path(source_list), alert: "Task is already in that list."
      return
    end

    @task_item.update!(task_list: target_list)

    redirect_to task_list_items_path(source_list), notice: "\"#{@task_item.name}\" moved to \"#{target_list.name}\"."
  end

  private

  def set_task_item
    @task_item = Current.task_items.find(params[:task_item_id])
    @task_list = Current.task_list
  end
end
