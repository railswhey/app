# frozen_string_literal: true

require "test_helper"

class APIV1MyTasksIndexTest < ActionDispatch::IntegrationTest
  test "#index responds with 401 when API token is missing or invalid" do
    headers = [ {}, api_v1_adapter.authorization_header(SecureRandom.hex(20)) ].sample

    get(api_v1_adapter.my__tasks_url, headers:)

    api_v1_adapter.assert_response_with_failure(:unauthorized)
  end

  test "#index responds with 200 with empty results" do
    user = users(:one)

    get(api_v1_adapter.my__tasks_url, headers: api_v1_adapter.authorization_header(user))

    data = api_v1_adapter.assert_response_with_success(:ok)

    assert_equal [], data
  end

  test "#index responds with 200 and returns assigned task items" do
    user = users(:one)

    task = create_task(user)
    task.update_column(:assigned_member_id, user.id)

    get(api_v1_adapter.my__tasks_url, headers: api_v1_adapter.authorization_header(user))

    data = api_v1_adapter.assert_response_with_success(:ok)

    json_response = response.parsed_body.with_indifferent_access

    assert_equal "array", json_response["type"]
    assert json_response.key?("counts")
    assert_equal 1, data.size
    assert_equal task.id, data.first["id"]
  end

  test "#index responds with 200 when filtering by incomplete" do
    user = users(:one)

    incomplete = create_task(user)
    incomplete.update_column(:assigned_member_id, user.id)

    completed = create_task(user, name: "Done", completed: true)
    completed.update_column(:assigned_member_id, user.id)

    get(api_v1_adapter.my__tasks_url(filter: "incomplete"), headers: api_v1_adapter.authorization_header(user))

    data = api_v1_adapter.assert_response_with_success(:ok)

    assert_equal 1, data.size
    assert_equal incomplete.id, data.first["id"]
  end

  test "#index responds with 200 when filtering by completed" do
    user = users(:one)

    incomplete = create_task(user)
    incomplete.update_column(:assigned_member_id, user.id)

    completed = create_task(user, name: "Done", completed: true)
    completed.update_column(:assigned_member_id, user.id)

    get(api_v1_adapter.my__tasks_url(filter: "completed"), headers: api_v1_adapter.authorization_header(user))

    data = api_v1_adapter.assert_response_with_success(:ok)

    assert_equal 1, data.size
    assert_equal completed.id, data.first["id"]
  end
end
