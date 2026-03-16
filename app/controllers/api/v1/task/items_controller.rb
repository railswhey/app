# frozen_string_literal: true

class API::V1::Task::ItemsController < API::V1::Task::Item::BaseController
  before_action :authenticate_user!
  before_action :require_task_list!
  before_action :set_task_item, only: %i[show update destroy]

  def index
    @task_items = Current.task_items.filter_by(params[:filter])
  end

  def show
  end

  def create
    @task_item = Current.task_items.new(task_item_params)

    if @task_item.save
      render :show, status: :created, location: api_v1_task_list_item_url(Current.task_list_id, @task_item)
    else
      render_json_with_model_failure(@task_item)
    end
  end

  def update
    if @task_item.update(task_item_params)
      render :show, status: :ok, location: api_v1_task_list_item_url(Current.task_list_id, @task_item)
    else
      render_json_with_model_failure(@task_item)
    end
  end

  def destroy
    @task_item.destroy!

    head :no_content
  end

  private

  def task_item_params
    params.require(:task_item).permit(:name, :description, :completed, :assigned_user_id)
  end
end
