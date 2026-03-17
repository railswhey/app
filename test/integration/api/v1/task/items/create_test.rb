# frozen_string_literal: true

require "test_helper"

class APIV1TaskItemsCreateTest < ActionDispatch::IntegrationTest
  test "#create responds with 401 when API token is invalid" do
    user = users(:one)
    params = { task_item: { name: "Foo" } }
    headers = [ {}, api_v1_adapter.authorization_header(SecureRandom.hex(20)) ].sample

    post(api_v1_adapter.task__items_url(member!(user).inbox, format: :json), params:, headers:)

    api_v1_adapter.assert_response_with_failure(:unauthorized)
  end

  test "#create responds with 400 when params are missing" do
    user = users(:one)
    params = [ {}, { task_item: {} }, { task: nil } ].sample

    post(
      api_v1_adapter.task__items_url(member!(user).inbox, format: :json),
      headers: api_v1_adapter.authorization_header(user),
      params:
    )

    api_v1_adapter.assert_response_with_failure(:bad_request)
  end

  test "#create responds with 404 when task list is not found" do
    user = users(:one)
    params = { task_item: { name: "Foo" } }

    post(
      api_v1_adapter.task__items_url(Task::List.maximum(:id) + 1, format: :json),
      headers: api_v1_adapter.authorization_header(user),
      params:
    )

    api_v1_adapter.assert_response_with_failure(:not_found)
  end

  test "#index responds with 404 when task list belongs to another user" do
    user = users(:one)
    task_list = task_lists(:two_inbox)
    params = { task_item: { name: "Foo" } }

    post(
      api_v1_adapter.task__items_url(task_list, format: :json),
      headers: api_v1_adapter.authorization_header(user),
      params:
    )

    api_v1_adapter.assert_response_with_failure(:not_found)
  end

  test "#create responds with 422 when name is invalid" do
    user = users(:one)
    params = { task_item: { name: [ nil, "" ].sample } }

    post(
      api_v1_adapter.task__items_url(member!(user).inbox, format: :json),
      headers: api_v1_adapter.authorization_header(user),
      params:
    )

    api_v1_adapter.assert_response_with_failure(:unprocessable_entity)
  end

  test "#create responds with 201 when task is created" do
    user = users(:one)
    params = { task_item: { name: "Foo" } }

    assert_difference -> { member!(user).inbox.items.count } do
      post(
        api_v1_adapter.task__items_url(member!(user).inbox, format: :json),
        headers: api_v1_adapter.authorization_header(user),
        params:
      )
    end

    json_data = api_v1_adapter.assert_response_with_success(:created)

    assert_equal "Foo", json_data["name"]

    assert member!(user).inbox.items.exists?(json_data["id"])
  end
end
