# frozen_string_literal: true

class User::RespondToTransferProcess < ApplicationJob
  ACCEPT = "accept"
  REJECT = "reject"

  def perform(transfer:, action:)
    success =
      case action
      when ACCEPT then transfer.facilitation.accept
      when REJECT then transfer.facilitation.reject
      else false
      end

    return [ :err, transfer ] unless success

    User.find_by!(uuid: transfer.initiated_by.uuid).then do |initiator|
      notification = User::Notification::Delivery.new(transfer)

      case action
      when ACCEPT then notification.transfer_accepted(to: initiator)
      when REJECT then notification.transfer_rejected(to: initiator)
      end
    end

    [ :ok, transfer ]
  end
end
