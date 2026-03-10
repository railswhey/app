# frozen_string_literal: true

require "test_helper"

class WebTaskListShowTest < ActionDispatch::IntegrationTest
  test "guest cannot view a task list" do
    user = users(:one)
    list = create_task_list(member!(user).account, name: "Private")

    get web_adapter.task__list_url(list)
    web_adapter.assert_unauthorized_access
  end

  test "user views task list show page with detail card" do
    user = users(:one)
    list = create_task_list(member!(user).account, name: "My List")
    web_adapter.sign_in(user)

    get web_adapter.task__list_url(list)
    assert_response :ok
    assert_select ".detail-card"
    assert_select ".detail-value", "My List"
  end

  test "user sees transfer link for non-inbox lists" do
    user = users(:one)
    list = create_task_list(member!(user).account, name: "Transferable")
    web_adapter.sign_in(user)

    get web_adapter.task__list_url(list)
    assert_response :ok
    assert_select "a", /Transfer/
  end

  test "user does not see transfer link for inbox" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.task__list_url(user.inbox)
    assert_response :ok
    assert_select "a", { text: /Transfer/, count: 0 }
  end
end
