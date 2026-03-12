# frozen_string_literal: true

require "test_helper"

class TransferMailerTest < ActionMailer::TestCase
  test "transfer_requested sends email to target account owner" do
    sender = users(:one)
    receiver = users(:two)
    list = sender.account.task_lists.create!(name: "Transfer Me")

    transfer = TaskListTransfer.create!(
      task_list: list,
      from_account: sender.account,
      to_account: receiver.account,
      transferred_by: sender
    )

    email = Task::ListTransferMailer.transfer_requested(transfer)

    assert_equal [ receiver.email ], email.to
    assert_equal "Transfer request: Transfer Me", email.subject
    assert_match sender.email, email.body.encoded
    assert_match "Transfer Me", email.body.encoded
    assert_match transfer.token, email.body.encoded
  end
end
