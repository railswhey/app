# frozen_string_literal: true

require "test_helper"

class WebTaskListsTest < ActionDispatch::IntegrationTest
  test "guest tries to access all task lists" do
    get(web_adapter.task__lists_url)

    web_adapter.assert_unauthorized_access
  end

  test "user views all task lists" do
    user = users(:one)

    create_task_list(member!(user).account, name: "Foo")

    web_adapter.sign_in(user)

    get(web_adapter.task__lists_url)

    assert_response :ok

    assert_select("td", /Inbox/)
    assert_select("td", "Foo")
  end

  test "user destroys a task list" do
    user = users(:one)

    create_task_list(member!(user).account, name: "Foo")

    web_adapter.sign_in(user)

    get(web_adapter.task__lists_url)

    assert_response :ok

    task_list = user.account.task_lists.find_by(name: "Foo")

    delete(web_adapter.task__list_url(task_list))

    assert_redirected_to web_adapter.task__items_url(user.inbox)

    follow_redirect!

    assert_response :ok

    assert_select(".notice-text", "Task list was successfully destroyed.")
  end

  test "user tries to destroy the inbox task list" do
    user = users(:one)

    web_adapter.sign_in(user)

    delete(web_adapter.task__list_url(member!(user).inbox))

    assert_redirected_to web_adapter.task__lists_url

    follow_redirect!

    assert_response :ok

    assert_select(".notice-text", "You cannot edit or delete the inbox.")
  end

  test "user tries to destroy a task list from another user" do
    user = users(:one)
    task_list = task_lists(:two_inbox)

    web_adapter.sign_in(user)

    delete(web_adapter.task__list_url(task_list))

    assert_response :not_found
  end
end
