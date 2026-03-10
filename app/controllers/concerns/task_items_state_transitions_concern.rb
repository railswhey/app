# frozen_string_literal: true

module TaskItemsStateTransitionsConcern
  extend ActiveSupport::Concern

  def complete
    @task_item.complete!

    respond_to do |format|
      format.html do
        redirect_to(next_location, notice: "Task item was successfully marked as completed.")
      end
      format.json { render :show, status: :ok, location: task_item_url(@task_item) }
    end
  end

  def incomplete
    @task_item.incomplete!

    respond_to do |format|
      format.html do
        redirect_to(next_location, notice: "Task item was successfully marked as incomplete.")
      end
      format.json { render :show, status: :ok, location: task_item_url(@task_item) }
    end
  end

  def move
    source_list = @task_list
    target_list = Current.account.task_lists.find_by(id: params[:target_list_id])

    unless target_list
      respond_to do |format|
        format.html { redirect_to task_list_task_items_path(source_list), alert: "Target list not found." }
        format.json { render_json_with_failure(status: :unprocessable_entity, message: "Target list not found.") }
      end
      return
    end

    if target_list == source_list
      respond_to do |format|
        format.html { redirect_to task_list_task_items_path(source_list), alert: "Task is already in that list." }
        format.json { render_json_with_failure(status: :unprocessable_entity, message: "Task is already in that list.") }
      end
      return
    end

    @task_item.update!(task_list: target_list)

    respond_to do |format|
      format.html { redirect_to task_list_task_items_path(source_list), notice: "\"#{@task_item.name}\" moved to \"#{target_list.name}\"." }
      format.json { render :show, status: :ok, location: task_list_task_item_url(target_list, @task_item) }
    end
  end
end
