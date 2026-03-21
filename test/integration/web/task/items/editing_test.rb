# frozen_string_literal: true

require "test_helper"

class WebTaskItemsEditingTest < ActionDispatch::IntegrationTest
  test "guest tries to access new task form" do
    get(web_adapter.edit_task__item_url(workspace_lists(:one_inbox), workspace_tasks(:one)))

    web_adapter.assert_unauthorized_access
  end

  test "guest tries to create a task" do
    put(
      web_adapter.task__item_url(workspace_lists(:one_inbox), workspace_tasks(:one)),
      params: { workspace_task: { name: "Foo" } }
    )

    web_adapter.assert_unauthorized_access
  end

  test "user tries to update a task from another user" do
    user = users(:one)
    task = workspace_tasks(:two)

    web_adapter.sign_in(user)

    put(web_adapter.task__item_url(task.list, task), params: { workspace_task: { name: "Foo" } })

    assert_response :not_found
  end

  test "user updates a task with valid data" do
    user = users(:one)
    task = workspace_tasks(:one)

    web_adapter.sign_in(user)

    get(web_adapter.edit_task__item_url(task.list, task))

    assert_response :ok

    assert_select("h2", "Editing task item")

    assert_select("input[type=\"text\"][value=\"#{task.name}\"]")

    assert_select("input[type=\"checkbox\"]:not(checked)")

    put(
      web_adapter.task__item_url(member!(user).inbox, task),
      params: { workspace_task: { name: "Bar", completed: true } }
    )

    assert_redirected_to web_adapter.task__items_url(member!(user).inbox)

    follow_redirect!

    assert_response :ok

    assert_select(".notice-text", "Task item was successfully updated.")

    assert_select("td", /Bar/)

    get(web_adapter.edit_task__item_url(task.list, task))

    assert_select("input[type=\"checkbox\"][checked]")
  end

  test "user updates a task with invalid data" do
    user = users(:one)
    task = workspace_tasks(:one)

    web_adapter.sign_in(user)

    put(web_adapter.task__item_url(task.list, task), params: { workspace_task: { name: "" } })

    assert_response :unprocessable_entity

    assert_select("li", "Name can't be blank")
  end
end
