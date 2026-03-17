# frozen_string_literal: true

class User::Notification
  class Delivery
    attr_reader :notifiable

    def initialize(notifiable)
      @notifiable = notifiable
    end

    def transfer_requested(to:) = notify(to, TRANSFER_REQUESTED)
    def transfer_accepted       = notify(notifiable.transferred_by, TRANSFER_ACCEPTED)
    def transfer_rejected       = notify(notifiable.transferred_by, TRANSFER_REJECTED)

    def invitation_received(to:) = notify(to, INVITATION_RECEIVED)
    def invitation_accepted      =  notify(notifiable.invited_by, INVITATION_ACCEPTED)

    private

    def notify(user, action)
      User::Notification.create!(user:, notifiable: notifiable, action:)
    end
  end
end
