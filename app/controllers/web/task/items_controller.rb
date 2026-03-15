# frozen_string_literal: true

class Web::Task::ItemsController < Web::BaseController
  before_action :authenticate_user!
  before_action :require_task_list!
  before_action :set_task_item, only: %i[show edit update destroy]

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

    if @task_item.save
      redirect_to(next_location, notice: "Task item was successfully created.")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @task_item.update(task_item_params)
      redirect_to(next_location, notice: "Task item was successfully updated.")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task_item.destroy!

    redirect_to(next_location, notice: "Task item was successfully destroyed.")
  end

  private

  def require_task_list!
    raise ActiveRecord::RecordNotFound unless Current.task_list_id
  end

  def set_task_item
    @task_item = Current.task_items.find(params[:id])
    @task_list = Current.task_list
  end

  def task_items_url(...)
    task_list_items_url(Current.task_list_id, ...)
  end

  def task_item_url(...)
    task_list_item_url(Current.task_list_id, ...)
  end

  def next_location
    return task_item_assignments_url if params[:return_to] == "task_item_assignments"
    case params[:filter]
    when "completed" then task_items_url(filter: "completed")
    when "incomplete" then task_items_url(filter: "incomplete")
    when "show" then task_item_url(@task_item)
    else task_items_url
    end
  end

  def task_item_params
    params.require(:task_item).permit(:name, :description, :completed, :assigned_user_id)
  end
end
