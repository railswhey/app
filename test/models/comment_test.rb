# frozen_string_literal: true

require "test_helper"

class Workspace::CommentTest < ActiveSupport::TestCase
  test "valid comment on task item" do
    comment = Workspace::Comment.new(body: "Looks good!", commentable: workspace_tasks(:one), member: workspace_members(:one))
    assert comment.valid?
  end

  test "valid comment on task list" do
    comment = Workspace::Comment.new(body: "Nice list", commentable: workspace_lists(:one_inbox), member: workspace_members(:one))
    assert comment.valid?
  end

  test "invalid without body" do
    comment = Workspace::Comment.new(body: "", commentable: workspace_tasks(:one), member: workspace_members(:one))
    assert comment.invalid?
    assert_includes comment.errors[:body], "can't be blank"
  end

  test "strips body whitespace" do
    comment = Workspace::Comment.new(body: "  trimmed  ", commentable: workspace_tasks(:one), member: workspace_members(:one))
    assert comment.valid?
    assert_equal "trimmed", comment.body
  end

  test "chronological scope orders by created_at asc" do
    member = workspace_members(:one)
    task = workspace_tasks(:one)
    task.comments.destroy_all

    older = task.comments.create!(body: "First", member:)
    newer = task.comments.create!(body: "Second", member:)

    assert_equal [ older, newer ], task.comments.chronological.to_a
  end

  test "search scope matches body" do
    comments = Workspace::Comment.search("comment on task item one")
    assert comments.any?
  end

  test "search_comments returns comments belonging to the account and excludes others" do
    account_one = accounts(:one)
    account_two = accounts(:two)
    workspace_one = ::Workspace.find_by!(uuid: account_one.uuid)
    workspace_two = ::Workspace.find_by!(uuid: account_two.uuid)

    # Create a list + item in account one and comment on each
    list_one = workspace_one.lists.create!(name: "List A")
    item_one = list_one.tasks.create!(name: "Item A")
    comment_on_item = item_one.comments.create!(body: "on item", member: workspace_members(:one))
    comment_on_list = list_one.comments.create!(body: "on list", member: workspace_members(:one))

    # Create a list + item in account two and comment on each
    list_two = workspace_two.lists.create!(name: "List B")
    item_two = list_two.tasks.create!(name: "Item B")
    comment_other_item = item_two.comments.create!(body: "other account item", member: workspace_members(:two))
    comment_other_list = list_two.comments.create!(body: "other account list", member: workspace_members(:two))

    result = workspace_one.search("on").comments

    assert result.exists?(id: comment_on_item.id),  "should include item comment from account one"
    assert result.exists?(id: comment_on_list.id),  "should include list comment from account one"
    assert_not result.exists?(id: comment_other_item.id), "should exclude item comment from account two"
    assert_not result.exists?(id: comment_other_list.id), "should exclude list comment from account two"
  end
end
