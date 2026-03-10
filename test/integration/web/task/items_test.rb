# frozen_string_literal: true

require "test_helper"

class WebTaskItemsTest < ActionDispatch::IntegrationTest
  test "guest tries to access all tasks" do
    get(web_adapter.task__items_url(task_lists(:one_inbox)))

    web_adapter.assert_unauthorized_access
  end

  test "guest tries to access completed tasks" do
    get(web_adapter.task__items_url(task_lists(:one_inbox), filter: "completed"))

    web_adapter.assert_unauthorized_access
  end

  test "guest tries to access incomplete tasks" do
    get(web_adapter.task__items_url(task_lists(:one_inbox), filter: "incomplete"))

    web_adapter.assert_unauthorized_access
  end

  test "user access all tasks" do
    user = users(:one)
    inbox = member!(user).inbox

    create_task(user, name: "Foo", completed: true)

    web_adapter.sign_in(user)

    get(web_adapter.task__items_url(inbox))

    assert_response :ok
    assert_select("select.action-combo", count: 2)

    # Delete tasks directly
    inbox.task_items.each do |item|
      delete(web_adapter.task__item_url(inbox, item))
      assert_redirected_to web_adapter.task__items_url(inbox)
      follow_redirect!
    end

    assert_select(".notice-text", "Task item was successfully destroyed.")
    assert_select(".empty-state")
  end

  test "user access completed tasks" do
    user = users(:one)
    inbox = member!(user).inbox
    task = task_items(:one)

    complete_task(task)

    web_adapter.sign_in(user)

    get(web_adapter.task__items_url(inbox, filter: "completed"))

    assert_response :ok

    # Mark incomplete via direct PUT
    put(web_adapter.incomplete_task__item_url(inbox, task, filter: "completed"))

    assert_redirected_to web_adapter.task__items_url(inbox, filter: "completed")
    follow_redirect!

    assert_select(".notice-text", "Task item was successfully marked as incomplete.")
  end

  test "user access incomplete tasks" do
    user = users(:one)
    inbox = member!(user).inbox
    task = task_items(:one)

    web_adapter.sign_in(user)

    get(web_adapter.task__items_url(inbox, filter: "incomplete"))

    assert_response :ok

    # Mark complete via direct PUT
    put(web_adapter.complete_task__item_url(inbox, task, filter: "incomplete"))

    assert_redirected_to web_adapter.task__items_url(inbox, filter: "incomplete")
    follow_redirect!

    assert_select(".notice-text", "Task item was successfully marked as completed.")
  end
end
