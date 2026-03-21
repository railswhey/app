# frozen_string_literal: true

require "test_helper"

class APIV1TaskItemsUpdateTest < ActionDispatch::IntegrationTest
  test "#update responds with 401 when API token is invalid" do
    user = users(:one)
    task = workspace_tasks(:one)
    params = { workspace_task: { name: "Foo" } }
    headers = [ {}, api_v1_adapter.authorization_header(SecureRandom.hex(20)) ].sample

    put(api_v1_adapter.task__item_url(member!(user).inbox, task, format: :json), params:, headers:)

    api_v1_adapter.assert_response_with_failure(:unauthorized)
  end

  test "#update responds with 400 when params are missing" do
    user = users(:one)
    task = workspace_tasks(:one)
    params = [ {}, { workspace_task: {} }, { task: nil } ].sample

    put(
      api_v1_adapter.task__item_url(member!(user).inbox, task, format: :json),
      headers: api_v1_adapter.authorization_header(user),
      params:
    )

    api_v1_adapter.assert_response_with_failure(:bad_request)
  end

  test "#update responds with 404 when task list is not found" do
    user = users(:one)
    task = workspace_tasks(:one)
    params = { workspace_task: { name: "Foo" } }

    url = api_v1_adapter.task__item_url(Workspace::List.maximum(:id) + 1, task.id, format: :json)

    put(url, params:, headers: api_v1_adapter.authorization_header(user))

    api_v1_adapter.assert_response_with_failure(:not_found)
  end

  test "#update responds with 404 when task is not found" do
    user = users(:one)
    params = { workspace_task: { name: "Foo" } }

    url = api_v1_adapter.task__item_url(member!(user).inbox, Workspace::Task.maximum(:id) + 1, format: :json)

    put(url, params:, headers: api_v1_adapter.authorization_header(user))

    api_v1_adapter.assert_response_with_failure(:not_found)
  end

  test "#update responds with 404 when task list belongs to another user" do
    user = users(:one)
    task = workspace_tasks(:two)
    params = { workspace_task: { name: "Foo" } }

    put(
      api_v1_adapter.task__item_url(task.list, task, format: :json),
      headers: api_v1_adapter.authorization_header(user),
      params:
    )

    api_v1_adapter.assert_response_with_failure(:not_found)
  end

  test "#update responds with 422 when name is invalid" do
    user = users(:one)
    task = workspace_tasks(:one)
    params = { workspace_task: { name: [ nil, "" ].sample } }

    put(
      api_v1_adapter.task__item_url(member!(user).inbox, task, format: :json),
      headers: api_v1_adapter.authorization_header(user),
      params:
    )

    api_v1_adapter.assert_response_with_failure(:unprocessable_entity)
  end

  test "#update responds with 200 when task is updated" do
    user = users(:one)
    task = workspace_tasks(:one)
    params = { workspace_task: { name: SecureRandom.hex } }

    put(
      api_v1_adapter.task__item_url(member!(user).inbox, task, format: :json),
      params:,
      headers: api_v1_adapter.authorization_header(user)
    )

    json_data = api_v1_adapter.assert_response_with_success(:ok)

    updated_task = member!(user).inbox.tasks.find(json_data["id"])

    assert_equal params[:workspace_task][:name], updated_task.name
  end

  test "#update responds with 200 when marking task as completed" do
    user = users(:one)
    task = workspace_tasks(:one)
    params = { workspace_task: { completed: [ true, 1, "1", "true" ].sample } }

    put(
      api_v1_adapter.task__item_url(member!(user).inbox, task, format: :json),
      headers: api_v1_adapter.authorization_header(user),
      params:
    )

    json_data = api_v1_adapter.assert_response_with_success(:ok)

    updated_task = member!(user).inbox.tasks.find(json_data["id"])

    assert updated_task.completed_at.present?
  end

  test "#update responds with 200 when marking task as incomplete" do
    user = users(:one)
    task = workspace_tasks(:one).then { complete_task(_1) }

    params = { workspace_task: { completed: [ false, 0, "0", "false" ].sample } }

    put(
      api_v1_adapter.task__item_url(member!(user).inbox, task, format: :json),
      headers: api_v1_adapter.authorization_header(user),
      params:
    )

    json_data = api_v1_adapter.assert_response_with_success(:ok)

    updated_task = member!(user).inbox.tasks.find(json_data["id"])

    assert updated_task.completed_at.blank?
  end
end
