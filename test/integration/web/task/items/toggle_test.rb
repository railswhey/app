# frozen_string_literal: true

require "test_helper"

class WebTaskItemsToggleTest < ActionDispatch::IntegrationTest
  test "user completes a task" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user, name: "Do it")
    web_adapter.sign_in(user)

    put web_adapter.complete_task__item_url(inbox, task)
    assert_redirected_to web_adapter.task__items_url(inbox)
    assert task.reload.completed?
  end

  test "user marks a task incomplete" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user, name: "Done", completed: true)
    web_adapter.sign_in(user)

    put web_adapter.incomplete_task__item_url(inbox, task)
    assert_redirected_to web_adapter.task__items_url(inbox)
    assert task.reload.incomplete?
  end

  test "user completes a task from the show page and returns to show" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user, name: "Show filter task")
    web_adapter.sign_in(user)

    put web_adapter.complete_task__item_url(inbox, task, filter: "show")
    assert_redirected_to web_adapter.task__item_url(inbox, task)
    assert task.reload.completed?
  end
end
