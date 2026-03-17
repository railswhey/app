# frozen_string_literal: true

require "test_helper"

class WebTaskItemsCrudTest < ActionDispatch::IntegrationTest
  test "guest cannot create a task item" do
    post web_adapter.task__items_url(task_lists(:one_inbox))
    web_adapter.assert_unauthorized_access
  end

  test "user creates a task item" do
    user = users(:one)
    inbox = member!(user).inbox
    web_adapter.sign_in(user)

    assert_difference "inbox.items.count", 1 do
      post web_adapter.task__items_url(inbox), params: { task_item: { name: "New task" } }
    end
    assert_redirected_to web_adapter.task__items_url(inbox)
  end

  test "user creates a task with invalid data" do
    user = users(:one)
    inbox = member!(user).inbox
    web_adapter.sign_in(user)

    post web_adapter.task__items_url(inbox), params: { task_item: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "user edits a task item" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user, name: "Old name")
    web_adapter.sign_in(user)

    get web_adapter.edit_task__item_url(inbox, task)
    assert_response :ok
    assert_select "input[value='Old name']"
  end

  test "user updates a task item" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user, name: "Old name")
    web_adapter.sign_in(user)

    put web_adapter.task__item_url(inbox, task), params: { task_item: { name: "New name" } }
    assert_redirected_to web_adapter.task__items_url(inbox)
    assert_equal "New name", task.reload.name
  end

  test "user updates task with invalid data" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user, name: "Valid")
    web_adapter.sign_in(user)

    put web_adapter.task__item_url(inbox, task), params: { task_item: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "user deletes a task item" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user, name: "Delete me")
    web_adapter.sign_in(user)

    assert_difference "inbox.items.count", -1 do
      delete web_adapter.task__item_url(inbox, task)
    end
    assert_redirected_to web_adapter.task__items_url(inbox)
  end

  test "user creates a new task form" do
    user = users(:one)
    inbox = member!(user).inbox
    web_adapter.sign_in(user)

    get web_adapter.new_task__item_url(inbox)
    assert_response :ok
  end

  test "user assigns a task to themselves" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user, name: "Assign me")
    web_adapter.sign_in(user)

    put web_adapter.task__item_url(inbox, task), params: { task_item: { assigned_user_id: user.id } }
    assert_redirected_to web_adapter.task__items_url(inbox)
    assert_equal user, task.reload.assigned_user
  end
end
