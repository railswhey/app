# frozen_string_literal: true

require "test_helper"

class WebTaskItemCommentsTest < ActionDispatch::IntegrationTest
  test "guest cannot create a comment" do
    inbox = workspace_lists(:one_inbox)
    task = workspace_tasks(:one)

    post web_adapter.task__item__comments_url(inbox, task), params: { comment: { body: "Hi" } }
    web_adapter.assert_unauthorized_access
  end

  test "user creates a comment on a task item" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user, name: "Commented task")
    web_adapter.sign_in(user)

    assert_difference "task.comments.count", 1 do
      post web_adapter.task__item__comments_url(inbox, task),
           params: { comment: { body: "Looking great!" } }
    end
    assert_redirected_to web_adapter.task__item_url(inbox, task)

    comment = task.comments.last
    assert_equal "Looking great!", comment.body
    assert_equal user.uuid, comment.member.uuid
  end

  test "user cannot create a blank comment" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user)
    web_adapter.sign_in(user)

    assert_no_difference "task.comments.count" do
      post web_adapter.task__item__comments_url(inbox, task),
           params: { comment: { body: "" } }
    end
    assert_redirected_to web_adapter.task__item_url(inbox, task)
  end

  test "user edits their own comment" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user)
    comment = create_comment(user, task, body: "Original")
    web_adapter.sign_in(user)

    get web_adapter.edit_task__item__comment_url(inbox, task, comment)
    assert_response :ok
    assert_select "textarea", /Original/
  end

  test "user updates their own comment" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user)
    comment = create_comment(user, task, body: "Original")
    web_adapter.sign_in(user)

    patch web_adapter.task__item__comment_url(inbox, task, comment),
          params: { comment: { body: "Updated body" } }
    assert_redirected_to web_adapter.task__item_url(inbox, task)
    assert_equal "Updated body", comment.reload.body
  end

  test "user cannot update comment with blank body" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user)
    comment = create_comment(user, task, body: "Valid body")
    web_adapter.sign_in(user)

    patch web_adapter.task__item__comment_url(inbox, task, comment),
          params: { comment: { body: "" } }
    assert_response :unprocessable_entity
    assert_equal "Valid body", comment.reload.body
  end

  test "user cannot update another user's comment" do
    owner = users(:one)
    other = users(:two)
    inbox = member!(owner).inbox
    task = create_task(owner)
    comment = create_comment(other, task, body: "Other's comment")
    web_adapter.sign_in(owner)

    patch web_adapter.task__item__comment_url(inbox, task, comment),
          params: { comment: { body: "Hijacked" } }
    assert_redirected_to web_adapter.task__item_url(inbox, task)
    assert_equal "Other's comment", comment.reload.body
  end

  test "user deletes their own comment" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user)
    comment = create_comment(user, task)
    web_adapter.sign_in(user)

    assert_difference "task.comments.count", -1 do
      delete web_adapter.task__item__comment_url(inbox, task, comment)
    end
    assert_redirected_to web_adapter.task__item_url(inbox, task)
  end

  test "user cannot delete another user's comment" do
    owner = users(:one)
    other = users(:two)
    inbox = member!(owner).inbox
    task = create_task(owner)
    comment = create_comment(other, task)
    web_adapter.sign_in(owner)

    assert_no_difference "task.comments.count" do
      delete web_adapter.task__item__comment_url(inbox, task, comment)
    end
    assert_redirected_to web_adapter.task__item_url(inbox, task)
  end
end
