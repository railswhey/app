# frozen_string_literal: true

class Task::ItemMovesController < ApplicationController
  include TaskItemsConcern

  before_action :authenticate_user!
  before_action :set_task_item

  def create
    source_list = @task_list
    target_list = Current.account.task_lists.find_by(id: params[:target_list_id])

    unless target_list
      respond_to do |format|
        format.html { redirect_to task_list_items_path(source_list), alert: "Target list not found." }
        format.json { render_json_with_failure(status: :unprocessable_entity, message: "Target list not found.") }
      end
      return
    end

    if target_list == source_list
      respond_to do |format|
        format.html { redirect_to task_list_items_path(source_list), alert: "Task is already in that list." }
        format.json { render_json_with_failure(status: :unprocessable_entity, message: "Task is already in that list.") }
      end
      return
    end

    @task_item.update!(task_list: target_list)

    respond_to do |format|
      format.html { redirect_to task_list_items_path(source_list), notice: "\"#{@task_item.name}\" moved to \"#{target_list.name}\"." }
      format.json { render "task/items/show", status: :ok, location: task_list_item_url(target_list, @task_item) }
    end
  end

  private

  def set_task_item
    @task_item = Current.task_items.find(params[:task_item_id])
    @task_list = Current.task_list
  end
end
