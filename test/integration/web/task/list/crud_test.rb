# frozen_string_literal: true

require "test_helper"

class WebTaskListCrudTest < ActionDispatch::IntegrationTest
  test "user accesses new task list form" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.new_task__list_url
    assert_response :ok
  end

  test "user edits a task list" do
    user = users(:one)
    list = create_task_list(member!(user).account, name: "Editable")
    web_adapter.sign_in(user)

    get web_adapter.edit_task__list_url(list)
    assert_response :ok
    assert_select "input[value='Editable']"
  end

  test "user cannot edit inbox" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.edit_task__list_url(user.inbox)
    assert_redirected_to web_adapter.task__lists_url
  end

  test "user cannot delete inbox" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    delete web_adapter.task__list_url(user.inbox)
    assert_redirected_to web_adapter.task__lists_url
  end
end
