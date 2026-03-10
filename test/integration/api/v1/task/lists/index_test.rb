# frozen_string_literal: true

require "test_helper"

class APIV1TaskListsIndexTest < ActionDispatch::IntegrationTest
  test "#index responds with 401 when API token is invalid" do
    headers = [ {}, api_v1_adapter.authorization_header(SecureRandom.hex(20)) ].sample

    get(api_v1_adapter.task__lists_url, headers:)

    api_v1_adapter.assert_response_with_failure(:unauthorized)
  end

  test "#index responds with 200" do
    user = users(:one)

    new_task_list = member!(user).account.task_lists.create!(name: "Foo")

    get(api_v1_adapter.task__lists_url, headers: api_v1_adapter.authorization_header(user))

    collection = api_v1_adapter.assert_response_with_success(:ok)

    assert_equal 2, collection.size

    assert collection.all? { member!(user).task_lists.exists?(_1[:id]) }

    assert_equal new_task_list.id, collection.find { _1[:name] == "Foo" }[:id]
  end
end
