# frozen_string_literal: true

require "test_helper"

class WebTaskItemsShowTest < ActionDispatch::IntegrationTest
  test "guest cannot view a task item" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user, name: "Secret")

    get web_adapter.task__item_url(inbox, task)
    web_adapter.assert_unauthorized_access
  end

  test "user views task item with detail card" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user, name: "Review PR")
    web_adapter.sign_in(user)

    get web_adapter.task__item_url(inbox, task)
    assert_response :ok
    assert_select ".detail-card"
    assert_select ".detail-value", "Review PR"
  end

  test "user views task item with description" do
    user = users(:one)
    inbox = member!(user).inbox
    task = inbox.items.create!(name: "Described", description: "Some details here")
    web_adapter.sign_in(user)

    get web_adapter.task__item_url(inbox, task)
    assert_response :ok
    assert_select ".detail-value", /Some details here/
  end

  test "user views assigned task item" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user, name: "Assigned")
    task.update!(assigned_user: user)
    web_adapter.sign_in(user)

    get web_adapter.task__item_url(inbox, task)
    assert_response :ok
    assert_select ".detail-value", user.username
  end
end
