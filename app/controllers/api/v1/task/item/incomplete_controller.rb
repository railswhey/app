# frozen_string_literal: true

class API::V1::Task::Item::IncompleteController < API::V1::Task::Item::BaseController
  before_action :authenticate_user!
  before_action :set_task_item

  def update
    @task_item.incomplete!

    render "api/v1/task/items/show", status: :ok, location: api_v1_task_list_item_url(Current.task_list_id, @task_item)
  end
end
