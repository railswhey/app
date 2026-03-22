# frozen_string_literal: true

class Account::DispatchInvitationProcess < ApplicationJob
  Manager = Orchestrator.new(:invitation, :notification) do
    def call(account:, invited_by:, email:)
      build_invitation(account:, invited_by:, email:)

      return [ :err, invitation ] unless invitation.valid?

      save_invitation
      notify_invitee(email:)
      send_invitation_email

      [ :ok, invitation ]
    rescue ActiveRecord::ActiveRecordError => e
      revert!

      [ :err, e ]
    end

    private

    def build_invitation(account:, invited_by:, email:)
      self.invitation = account.invitations.new(invited_by:, email:)
    end

    def save_invitation
      Account.transaction do
        invitation.save!
      end
    end

    def notify_invitee(email:)
      User.find_by(email:)&.then do |user|
        self.notification = User::Notification::Delivery.new(invitation).invitation_received(to: user)
      end
    end

    def send_invitation_email
      Account::InvitationMailer.invite(invitation).deliver_later
    end

    def revert!
      undo(notification)           { notification.destroy! }
      undo(invitation&.persisted?) { invitation.destroy! }
    end
  end

  def perform(...) = Manager.new.call(...)
end
