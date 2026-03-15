# frozen_string_literal: true

class API::V1::Task::ListsController < API::V1::BaseController
  before_action :authenticate_user!
  before_action :set_task_list, only: %i[show update destroy]
  before_action only: [ :update, :destroy ], if: -> { @task_list.inbox? } do
    render_json_with_failure(status: :forbidden, message: "Inbox cannot be updated or deleted")
  end

  rescue_from ActiveRecord::RecordNotFound do
    render_json_with_failure(status: :not_found, message: "Task list not found")
  end

  def index
    @task_lists = Current.task_lists
  end

  def show
    items               = @task_list.task_items
    @items_total        = items.count
    @items_done         = items.completed.count
    @items_pending      = @items_total - @items_done
    @items_pct          = @items_total > 0 ? (@items_done * 100.0 / @items_total).round : 0
    @preview_items      = items.incomplete.order(created_at: :desc).limit(5).includes(:assigned_user)
    @list_comments      = @task_list.comments.chronological.includes(:user)
  end

  def create
    @task_list = Current.task_lists.new(task_list_params)

    if @task_list.save
      render :show, status: :created, location: api_v1_task_list_url(@task_list)
    else
      render_json_with_model_failure(@task_list)
    end
  end

  def update
    if @task_list.update(task_list_params)
      render :show, status: :ok, location: api_v1_task_list_url(@task_list)
    else
      render_json_with_model_failure(@task_list)
    end
  end

  def destroy
    @task_list.destroy!

    head :no_content
  end

  private

  def set_task_list
    @task_list = Current.task_lists.find(params[:id])
  end

  def task_list_params
    params.require(:task_list).permit(:name, :description)
  end
end
