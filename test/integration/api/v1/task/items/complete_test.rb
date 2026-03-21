# frozen_string_literal: true

require "test_helper"

class APIV1TaskItemsCompleteTest < ActionDispatch::IntegrationTest
  test "#update responds with 401 when API token is invalid" do
    user = users(:one)
    task = workspace_tasks(:one)
    headers = [ {}, api_v1_adapter.authorization_header(SecureRandom.hex(20)) ].sample

    put(api_v1_adapter.complete_task__item_url(member!(user).inbox, task, format: :json), headers:)

    api_v1_adapter.assert_response_with_failure(:unauthorized)
  end

  test "#update responds with 404 when task list is not found" do
    user = users(:one)
    task = workspace_tasks(:one)

    url = api_v1_adapter.complete_task__item_url(Workspace::List.maximum(:id) + 1, task.id, format: :json)

    put(url, headers: api_v1_adapter.authorization_header(user))

    api_v1_adapter.assert_response_with_failure(:not_found)
  end

  test "#update responds with 404 when task is not found" do
    user = users(:one)

    url = api_v1_adapter.complete_task__item_url(member!(user).inbox, Workspace::Task.maximum(:id) + 1, format: :json)

    put(url, headers: api_v1_adapter.authorization_header(user))

    api_v1_adapter.assert_response_with_failure(:not_found)
  end

  test "#update responds with 404 when task list belongs to another user" do
    user = users(:one)
    task = workspace_tasks(:two)

    put(
      api_v1_adapter.complete_task__item_url(task.list, task, format: :json),
      headers: api_v1_adapter.authorization_header(user)
    )

    api_v1_adapter.assert_response_with_failure(:not_found)
  end

  test "#update responds with 200 when task is marked as completed" do
    user = users(:one)

    task = workspace_tasks(:one).then { incomplete_task(_1) }

    assert_changes -> { task.reload.completed_at } do
      put(
        api_v1_adapter.complete_task__item_url(member!(user).inbox, task, format: :json),
        headers: api_v1_adapter.authorization_header(user)
      )
    end

    assert_kind_of(Time, task.completed_at)

    json_data = api_v1_adapter.assert_response_with_success(:ok)

    assert_equal(task.id, json_data[:id])
    assert_not_nil(json_data[:completed_at])
  end
end
