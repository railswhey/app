# frozen_string_literal: true

require "test_helper"

class CommentTest < ActiveSupport::TestCase
  test "valid comment on task item" do
    comment = Comment.new(body: "Looks good!", commentable: task_items(:one), user: users(:one))
    assert comment.valid?
  end

  test "valid comment on task list" do
    comment = Comment.new(body: "Nice list", commentable: task_lists(:one_inbox), user: users(:one))
    assert comment.valid?
  end

  test "invalid without body" do
    comment = Comment.new(body: "", commentable: task_items(:one), user: users(:one))
    assert comment.invalid?
    assert_includes comment.errors[:body], "can't be blank"
  end

  test "strips body whitespace" do
    comment = Comment.new(body: "  trimmed  ", commentable: task_items(:one), user: users(:one))
    assert comment.valid?
    assert_equal "trimmed", comment.body
  end

  test "chronological scope orders by created_at asc" do
    user = users(:one)
    task = task_items(:one)
    task.comments.destroy_all

    older = task.comments.create!(body: "First", user:)
    newer = task.comments.create!(body: "Second", user:)

    assert_equal [ older, newer ], task.comments.chronological.to_a
  end

  test "search scope matches body" do
    comments = Comment.search("comment on task item one")
    assert comments.any?
  end

  test "for_account returns comments belonging to the account and excludes others" do
    account_one = accounts(:one)
    account_two = accounts(:two)

    # Create a list + item in account one and comment on each
    list_one = account_one.task_lists.create!(name: "List A")
    item_one = list_one.task_items.create!(name: "Item A")
    comment_on_item = item_one.comments.create!(body: "on item", user: users(:one))
    comment_on_list = list_one.comments.create!(body: "on list", user: users(:one))

    # Create a list + item in account two and comment on each
    list_two = account_two.task_lists.create!(name: "List B")
    item_two = list_two.task_items.create!(name: "Item B")
    comment_other_item = item_two.comments.create!(body: "other account item", user: users(:two))
    comment_other_list = list_two.comments.create!(body: "other account list", user: users(:two))

    result = Comment.for_account(account_one.id)

    assert result.exists?(id: comment_on_item.id),  "should include item comment from account one"
    assert result.exists?(id: comment_on_list.id),  "should include list comment from account one"
    assert_not result.exists?(id: comment_other_item.id), "should exclude item comment from account two"
    assert_not result.exists?(id: comment_other_list.id), "should exclude list comment from account two"
  end
end
