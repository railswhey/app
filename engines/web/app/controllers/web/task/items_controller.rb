# frozen_string_literal: true

class Web::Task::ItemsController < Web::Task::Item::BaseController
  before_action :authenticate_user!
  before_action :require_task_list!
  before_action :set_task_item, only: %i[show edit update destroy]

  def index
    @task_items = current.tasks.filter_by(params[:filter])
  end

  def show
    @comments = @task_item.comments.chronological.includes(:member)
  end

  def new
    @task_item = current.tasks.new
  end

  def edit
  end

  def create
    @task_item = current.tasks.new(task_item_params)

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

  def task_item_params
    params.require(:workspace_task).permit(:name, :description, :completed, :assigned_member_id)
  end
end
