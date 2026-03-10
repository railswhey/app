# frozen_string_literal: true

require "test_helper"

class TaskListTransferTest < ActiveSupport::TestCase
  setup do
    @from_account = accounts(:one)
    @to_account   = accounts(:two)
    @owner_one    = users(:one)
    @owner_two    = users(:two)
    @task_list    = @from_account.task_lists.create!(name: "Work Tasks")
  end

  def build_transfer(attrs = {})
    TaskListTransfer.new({
      task_list:      @task_list,
      from_account:   @from_account,
      to_account:     @to_account,
      transferred_by: @owner_one
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
    transfer = build_transfer(to_account: @from_account)
    assert transfer.invalid?
    assert transfer.errors[:to_account].present?
  end

  test "task_list_must_belong_to_from_account" do
    other_list = task_lists(:two_inbox)   # belongs to account two, not account one
    transfer = build_transfer(task_list: other_list)
    assert transfer.invalid?
    assert transfer.errors[:task_list].present?
  end

  test "starts as pending" do
    transfer = build_transfer
    transfer.save!
    assert transfer.pending?
  end

  test "accept! moves task list to target account" do
    transfer = build_transfer
    transfer.save!

    assert transfer.accept!(@owner_two)
    assert transfer.reload.accepted?
    assert_equal @to_account.id, @task_list.reload.account_id
  end

  test "accept! returns false if not pending" do
    transfer = build_transfer
    transfer.save!
    transfer.update_columns(status: TaskListTransfer.statuses[:accepted])

    assert_not transfer.accept!(@owner_two)
  end

  test "accept! returns false if user is not owner/admin of target account" do
    transfer = build_transfer
    transfer.save!

    # owner_one is not an owner/admin of to_account
    assert_not transfer.accept!(@owner_one)
  end

  test "reject! marks transfer rejected" do
    transfer = build_transfer
    transfer.save!

    assert transfer.reject!(@owner_two)
    assert transfer.reload.rejected?
  end

  test "reject! returns false if not pending" do
    transfer = build_transfer
    transfer.save!
    transfer.update_columns(status: TaskListTransfer.statuses[:rejected])

    assert_not transfer.reject!(@owner_two)
  end

  test "reject! returns false if user is not owner/admin of target account" do
    transfer = build_transfer
    transfer.save!

    assert_not transfer.reject!(@owner_one)
  end
end
