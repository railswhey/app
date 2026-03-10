# frozen_string_literal: true

class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @accept_url = show_invitation_url(invitation.token)

    mail(
      to: invitation.email,
      subject: "You've been invited to #{invitation.account.name}"
    )
  end
end
