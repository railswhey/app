# frozen_string_literal: true

class TaskItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_task_list!, only: %i[index new create show edit update destroy]
  before_action :set_task_item, only: %i[show edit update destroy complete incomplete move]

  rescue_from ActiveRecord::RecordNotFound do |exception|
    raise exception unless request.format.json?

    render_json_with_failure(status: :not_found, message: "Task list or item not found")
  end

  def index
    task_items = Current.task_items

    @task_items =
      case params[:filter]
      when "completed" then task_items.completed.order(completed_at: :desc)
      when "incomplete" then task_items.incomplete.order(created_at: :desc)
      else task_items.order(Arel.sql("task_items.completed_at DESC NULLS FIRST, task_items.created_at DESC"))
      end
  end

  def show
  end

  def new
    @task_item = Current.task_items.new
  end

  def edit
  end

  def create
    @task_item = Current.task_items.new(task_item_params)

    respond_to do |format|
      if @task_item.save
        format.html do
          redirect_to(next_location, notice: "Task item was successfully created.")
        end
        format.json do
          render :show, status: :created, location: task_item_url(@task_item)
        end
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render_json_with_model_failure(@task_item) }
      end
    end
  end

  def update
    respond_to do |format|
      if @task_item.update(task_item_params)
        format.html do
          redirect_to(next_location, notice: "Task item was successfully updated.")
        end
        format.json { render :show, status: :ok, location: task_item_url(@task_item) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render_json_with_model_failure(@task_item) }
      end
    end
  end

  def destroy
    @task_item.destroy!

    respond_to do |format|
      format.html do
        redirect_to(next_location, notice: "Task item was successfully destroyed.")
      end
      format.json { head :no_content }
    end
  end

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

  private

  def require_task_list!
    raise ActiveRecord::RecordNotFound unless Current.task_list_id
  end

  def set_task_item
    @task_item = Current.task_items.find(params[:id])
    @task_list = Current.task_list
  end

  def task_item_params
    params.require(:task_item).permit(:name, :description, :completed, :assigned_user_id)
  end

  def task_items_url(...)
    task_list_task_items_url(Current.task_list_id, ...)
  end

  def task_item_url(...)
    task_list_task_item_url(Current.task_list_id, ...)
  end

  def next_location
    return my_tasks_url if params[:return_to] == "my_tasks"
    case params[:filter]
    when "completed" then task_items_url(filter: "completed")
    when "incomplete" then task_items_url(filter: "incomplete")
    when "show" then task_item_url(@task_item)
    else task_items_url
    end
  end
end
