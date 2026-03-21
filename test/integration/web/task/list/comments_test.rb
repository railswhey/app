# frozen_string_literal: true

require "test_helper"

class WebTaskListCommentsTest < ActionDispatch::IntegrationTest
  test "guest cannot create a comment on a list" do
    list = workspace_lists(:one_inbox)

    post web_adapter.task_list__comments_url(list), params: { comment: { body: "Hi" } }
    web_adapter.assert_unauthorized_access
  end

  test "user creates a comment on a task list" do
    user = users(:one)
    inbox = member!(user).inbox
    web_adapter.sign_in(user)

    assert_difference "inbox.comments.count", 1 do
      post web_adapter.task_list__comments_url(inbox),
           params: { comment: { body: "Great list!" } }
    end
    assert_redirected_to web_adapter.task__list_url(inbox)

    comment = inbox.comments.last
    assert_equal "Great list!", comment.body
    assert_equal user.uuid, comment.member.uuid
  end

  test "user cannot create a blank comment on a list" do
    user = users(:one)
    inbox = member!(user).inbox
    web_adapter.sign_in(user)

    assert_no_difference "inbox.comments.count" do
      post web_adapter.task_list__comments_url(inbox),
           params: { comment: { body: "" } }
    end
    assert_redirected_to web_adapter.task__list_url(inbox)
  end

  test "user edits their own list comment" do
    user = users(:one)
    inbox = member!(user).inbox
    comment = create_comment(user, inbox, body: "Original list comment")
    web_adapter.sign_in(user)

    get web_adapter.edit_task_list__comment_url(inbox, comment)
    assert_response :ok
    assert_select "textarea", /Original list comment/
  end

  test "user updates their own list comment" do
    user = users(:one)
    inbox = member!(user).inbox
    comment = create_comment(user, inbox, body: "Original")
    web_adapter.sign_in(user)

    patch web_adapter.task_list__comment_url(inbox, comment),
          params: { comment: { body: "Updated list comment" } }
    assert_redirected_to web_adapter.task__list_url(inbox)
    assert_equal "Updated list comment", comment.reload.body
  end

  test "user cannot update another user's list comment" do
    owner = users(:one)
    other = users(:two)
    owner_inbox = member!(owner).inbox

    # other must be a member to have posted a comment (simulate via direct create)
    comment = owner_inbox.comments.create!(body: "Other's comment", member: Workspace::Member.find_by!(uuid: other.uuid))

    web_adapter.sign_in(owner)

    patch web_adapter.task_list__comment_url(owner_inbox, comment),
          params: { comment: { body: "Hijacked" } }
    assert_redirected_to web_adapter.task__list_url(owner_inbox)
    assert_equal "Other's comment", comment.reload.body
  end

  test "user deletes their own list comment" do
    user = users(:one)
    inbox = member!(user).inbox
    comment = create_comment(user, inbox)
    web_adapter.sign_in(user)

    assert_difference "inbox.comments.count", -1 do
      delete web_adapter.task_list__comment_url(inbox, comment)
    end
    assert_redirected_to web_adapter.task__list_url(inbox)
  end
end
