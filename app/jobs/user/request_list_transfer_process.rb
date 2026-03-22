# frozen_string_literal: true

class User::RequestListTransferProcess < ApplicationJob
  Manager = Orchestrator.new(:to_user, :account, :transfer, :notification) do
    def call(list:, from_workspace:, initiated_by:, to_email:)
      self.to_user = User.find_by(email: to_email)

      return [ :err, "No user found with that email." ] unless to_user

      self.account = resolve_account

      return [ :err, "Target user has no account." ] unless account

      create_transfer(list:, from_workspace:, initiated_by:)
      notify_recipient
      send_transfer_email

      [ :ok, transfer ]
    rescue ActiveRecord::ActiveRecordError => e
      revert!

      [ :err, e ]
    end

    private

    def resolve_account
      Account.joins(memberships: :person).find_by(account_people: { uuid: to_user.uuid })
    end

    def create_transfer(list:, from_workspace:, initiated_by:)
      to_workspace = ::Workspace.find_by(uuid: account.uuid)

      self.transfer = Workspace::List::Transfer.create!(list:, initiated_by:, from_workspace:, to_workspace:)
    end

    def notify_recipient
      self.notification = User::Notification::Delivery.new(transfer).transfer_requested(to: to_user)
    end

    def send_transfer_email
      Workspace::ListTransferMailer.with(recipient_email: account.owner.email, to_account_name: account.name)
                                   .transfer_requested(transfer).deliver_later
    end

    def revert!
      undo(notification) { notification.destroy! }
      undo(transfer)     { transfer.destroy! }
    end
  end

  def perform(...) = Manager.new.call(...)
end
