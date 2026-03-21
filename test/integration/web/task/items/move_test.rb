# frozen_string_literal: true

require "test_helper"

class WebTaskItemsMoveTest < ActionDispatch::IntegrationTest
  test "user moves a task to another list" do
    user = users(:one)
    account = member!(user).account
    source = ::Workspace.find_by!(uuid: account.uuid).lists.inbox.first
    target = create_task_list(account, name: "Target")
    task = create_task(user, name: "Movable", task_list: source)

    web_adapter.sign_in(user)

    post web_adapter.move_task__item_url(source, task, target_list_id: target.id)
    assert_redirected_to web_adapter.task__items_url(source)
    follow_redirect!
    assert_select ".notice-text", /moved to "Target"/
    assert_equal target, task.reload.list
  end

  test "move to same list shows alert" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user, name: "Stuck")

    web_adapter.sign_in(user)

    post web_adapter.move_task__item_url(inbox, task, target_list_id: inbox.id)
    assert_redirected_to web_adapter.task__items_url(inbox)
    follow_redirect!
    assert_select ".notice-text", /already in that list/
  end

  test "move to invalid list shows alert" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user, name: "Lost")

    web_adapter.sign_in(user)

    post web_adapter.move_task__item_url(inbox, task, target_list_id: 999999)
    assert_redirected_to web_adapter.task__items_url(inbox)
    follow_redirect!
    assert_select ".notice-text", /not found/
  end
end
