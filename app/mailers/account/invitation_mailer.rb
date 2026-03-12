# frozen_string_literal: true

class Account::InvitationMailer < ApplicationMailer
  default template_path: "account/mailers/invitation"

  def invite(invitation)
    @invitation = invitation
    @accept_url = show_invitation_url(invitation.token)

    mail(
      to: invitation.email,
      subject: "You've been invited to #{invitation.account.name}"
    )
  end
end
