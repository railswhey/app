# frozen_string_literal: true

class Account::InvitationMailer < ApplicationMailer
  default template_path: "mailers/account/invitation"

  def invite(invitation)
    @invitation = invitation
    @accept_url = account_invitations_acceptance_url(token: invitation.token)

    mail(
      to: invitation.email,
      subject: "You've been invited to #{invitation.account.name}"
    )
  end
end
