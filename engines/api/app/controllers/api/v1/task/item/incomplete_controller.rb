# frozen_string_literal: true

class API::V1::Task::Item::IncompleteController < API::V1::Task::Item::BaseController
  before_action :authenticate_user!
  before_action :set_task_item

  def update
    @task_item.incomplete!

    render "task/items/show", status: :ok, location: v1_task_list_item_url(current.task_list_id, @task_item)
  end
end
