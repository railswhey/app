# frozen_string_literal: true

class User::RequestListTransferProcess < ApplicationJob
  def perform(list:, from_workspace:, initiated_by:, to_email:)
    to_user = User.find_by(email: to_email)

    return [ :err, "No user found with that email." ] unless to_user

    person  = Account::Person.find_by(uuid: to_user.uuid)
    account = person&.ownership&.account

    return [ :err, "Target user has no account." ] unless account

    workspace = ::Workspace.find_by(uuid: account.uuid)

    transfer = Workspace::List::Transfer.new(
      list:,
      initiated_by:,
      to_workspace: workspace,
      from_workspace:,
    )

    transfer.facilitation.request

    return [ :err, transfer ] unless transfer.persisted?

    User::Notification::Delivery.new(transfer).transfer_requested(to: to_user)

    Workspace::ListTransferMailer.with(recipient_email: account.owner.email, to_account_name: account.name)
                                 .transfer_requested(transfer).deliver_later

    [ :ok, transfer ]
  end
end
