# frozen_string_literal: true

require "test_helper"

class APIV1SearchShowTest < ActionDispatch::IntegrationTest
  test "#show responds with 401 when API token is missing or invalid" do
    headers = [ {}, api_v1_adapter.authorization_header(SecureRandom.hex(20)) ].sample

    get(api_v1_adapter.search__url(q: "test"), headers:)

    api_v1_adapter.assert_response_with_failure(:unauthorized)
  end

  test "#show responds with 200 and empty results when query is below threshold" do
    user = users(:one)

    get(api_v1_adapter.search__url(q: "ab"), headers: api_v1_adapter.authorization_header(user))

    json_response = response.parsed_body.with_indifferent_access

    assert_response :ok
    assert_equal "success", json_response["status"]
    assert_equal "object", json_response["type"]
    assert_equal [], json_response.dig("data", "task_items")
    assert_equal [], json_response.dig("data", "task_lists")
  end

  test "#show responds with 200 and empty results when no query param" do
    user = users(:one)

    get(api_v1_adapter.search__url, headers: api_v1_adapter.authorization_header(user))

    json_response = response.parsed_body.with_indifferent_access

    assert_response :ok
    assert_equal "success", json_response["status"]
    assert_equal "object", json_response["type"]
    assert_equal [], json_response.dig("data", "task_items")
    assert_equal [], json_response.dig("data", "task_lists")
  end

  test "#show responds with 200 and returns matching task items and task lists" do
    user = users(:one)

    task = create_task(user, name: "Unicorn task")
    list = create_task_list(member!(user).account, name: "Unicorn list")

    get(api_v1_adapter.search__url(q: "Unicorn"), headers: api_v1_adapter.authorization_header(user))

    json_response = response.parsed_body.with_indifferent_access

    assert_response :ok
    assert_equal "success", json_response["status"]
    assert_equal "object", json_response["type"]

    task_items = json_response.dig("data", "task_items")
    task_lists = json_response.dig("data", "task_lists")

    assert_kind_of Array, task_items
    assert_kind_of Array, task_lists

    assert task_items.any? { |t| t["id"] == task.id }
    assert task_lists.any? { |l| l["id"] == list.id }
  end
end
