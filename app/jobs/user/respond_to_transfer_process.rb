# frozen_string_literal: true

class User::RespondToTransferProcess < ApplicationJob
  ACCEPT = "accept"
  REJECT = "reject"

  Manager = Orchestrator.new(:notification) do
    def call(transfer:, action:)
      success = respond(transfer:, action:)

      return [ :err, transfer ] unless success

      notify_initiator(transfer:, action:)

      [ :ok, transfer ]
    rescue ActiveRecord::ActiveRecordError => e
      [ :err, e ]
    end

    private

    def respond(transfer:, action:)
      case action
      when ACCEPT then transfer.facilitation.accept
      when REJECT then transfer.facilitation.reject
      else false
      end
    end

    def notify_initiator(transfer:, action:)
      initiator = User.find_by!(uuid: transfer.initiated_by.uuid)
      delivery = User::Notification::Delivery.new(transfer)

      self.notification = case action
      when ACCEPT then delivery.transfer_accepted(to: initiator)
      when REJECT then delivery.transfer_rejected(to: initiator)
      end
    end
  end

  def perform(...) = Manager.new.call(...)
end
