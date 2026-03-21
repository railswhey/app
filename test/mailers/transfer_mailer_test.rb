# frozen_string_literal: true

require "test_helper"

class TransferMailerTest < ActionMailer::TestCase
  test "transfer_requested sends email to target account owner" do
    sender = users(:one)
    receiver = users(:two)
    sender_account = member!(sender).account
    receiver_account = member!(receiver).account
    sender_workspace = ::Workspace.find_by!(uuid: sender_account.uuid)
    receiver_workspace = ::Workspace.find_by!(uuid: receiver_account.uuid)
    list = sender_workspace.lists.create!(name: "Transfer Me")

    transfer = Workspace::List::Transfer.create!(
      list: list,
      from_workspace: sender_workspace,
      to_workspace: receiver_workspace,
      initiated_by: workspace_members(:one)
    )

    email = Workspace::ListTransferMailer.with(recipient_email: receiver.email, to_account_name: receiver_account.name).transfer_requested(transfer)

    assert_equal [ receiver.email ], email.to
    assert_equal "Transfer request: Transfer Me", email.subject
    assert_match sender.email, email.body.encoded
    assert_match "Transfer Me", email.body.encoded
    assert_match transfer.token, email.body.encoded
  end
end
