# frozen_string_literal: true

class Account::DispatchInvitationProcess < ApplicationJob
  def perform(account:, invited_by:, email:)
    invitation = account.invitations.new(invited_by:, email:)

    return [ :err, invitation ] unless invitation.valid?

    ActiveRecord::Base.transaction do
      invitation.save!

      User.find_by(email:).try do
        User::Notification::Delivery.new(invitation).invitation_received(to: it)
      end
    end

    if invitation.persisted?
      Account::InvitationMailer.invite(invitation).deliver_later

      [ :ok, invitation ]
    else
      [ :err, invitation ]
    end
  end
end
