# frozen_string_literal: true

class Account::AcceptInvitationProcess < ApplicationJob
  def perform(invitation:, user:)
    ActiveRecord::Base.transaction do
      return [ :err, invitation ] unless invitation.accept!

      account = invitation.account

      uuid, email, username = user.values_at(:uuid, :email, :username)

      Account::AddPerson.new(account:).call(uuid:, email:, username:)

      Workspace::AddMember.new(workspace_uuid: account.uuid).call(uuid:, email:, username:)

      User.find_by!(uuid: invitation.invited_by.uuid).then do |inviter|
        User::Notification::Delivery.new(invitation).invitation_accepted(to: inviter)
      end
    end

    [ :ok, invitation ]
  end
end
