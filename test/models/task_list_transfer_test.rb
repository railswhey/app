# frozen_string_literal: true

require "test_helper"

class Workspace::List::TransferTest < ActiveSupport::TestCase
  setup do
    @from_workspace = workspaces(:one)
    @to_workspace   = workspaces(:two)
    @member_one     = workspace_members(:one)
    @member_two     = workspace_members(:two)
    @workspace_list = @from_workspace.lists.create!(name: "Work Tasks")
  end

  def build_transfer(attrs = {})
    Workspace::List::Transfer.new({
      list:           @workspace_list,
      from_workspace: @from_workspace,
      to_workspace:   @to_workspace,
      initiated_by:   @member_one
    }.merge(attrs))
  end

  test "valid transfer" do
    transfer = build_transfer
    assert transfer.valid?
  end

  test "generates token automatically" do
    transfer = build_transfer
    transfer.save!
    assert transfer.token.present?
  end

  test "accounts_must_differ" do
    transfer = build_transfer(to_workspace: @from_workspace)
    assert transfer.invalid?
    assert transfer.errors[:to_workspace].present?
  end

  test "task_list_must_belong_to_from_account" do
    other_list = workspace_lists(:two_inbox)   # belongs to workspace two, not workspace one
    transfer = build_transfer(list: other_list)
    assert transfer.invalid?
    assert transfer.errors[:list].present?
  end

  test "starts as pending" do
    transfer = build_transfer
    transfer.save!
    assert transfer.pending?
  end

  test "accept! moves task list to target account" do
    transfer = build_transfer
    transfer.save!

    assert transfer.accept!
    assert transfer.reload.accepted?
    assert_equal @to_workspace.id, @workspace_list.reload.workspace_id
  end

  test "accept! returns false if not pending" do
    transfer = build_transfer
    transfer.save!
    transfer.update_columns(status: Workspace::List::Transfer.statuses[:accepted])

    assert_not transfer.accept!
  end

  test "reject! marks transfer rejected" do
    transfer = build_transfer
    transfer.save!

    assert transfer.reject!
    assert transfer.reload.rejected?
  end

  test "reject! returns false if not pending" do
    transfer = build_transfer
    transfer.save!
    transfer.update_columns(status: Workspace::List::Transfer.statuses[:rejected])

    assert_not transfer.reject!
  end
end
