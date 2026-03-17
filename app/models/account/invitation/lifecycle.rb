# frozen_string_literal: true

class Account::Invitation::Lifecycle
  attr_reader :invitation

  def initialize(invitation)
    @invitation = invitation
  end

  def dispatch
    return invitation unless invitation.save

    Account::InvitationMailer.invite(invitation).deliver_later

    if (invitee = User.find_by(email: invitation.email))
      User::Notification::Delivery.new(invitation).invitation_received(to: invitee)
    end

    invitation
  end

  def accept(by:)
    return false if invitation.accepted?

    invitation.transaction do
      invitation.account.add_member(by, role: :collaborator)

      invitation.update_column(:accepted_at, Time.current)

      User::Notification::Delivery.new(invitation).invitation_accepted
    end

    true
  end
end
