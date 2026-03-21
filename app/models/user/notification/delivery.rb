# frozen_string_literal: true

class User::Notification
  class Delivery
    attr_reader :notifiable

    def initialize(notifiable)
      @notifiable = notifiable
    end

    def transfer_requested(to:) = notify(to, TRANSFER_REQUESTED)
    def transfer_accepted(to:)  = notify(to, TRANSFER_ACCEPTED)
    def transfer_rejected(to:)  = notify(to, TRANSFER_REJECTED)

    def invitation_received(to:) = notify(to, INVITATION_RECEIVED)
    def invitation_accepted(to:) = notify(to, INVITATION_ACCEPTED)

    private

    def notify(user, action)
      User::Notification.create!(user:, notifiable:, action:)
    end
  end
end
