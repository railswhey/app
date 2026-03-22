# frozen_string_literal: true

class Account::AcceptInvitationProcess < ApplicationJob
  Manager = Orchestrator.new(:person, :member, :notification) do
    def call(user:, invitation:)
      account = invitation.account

      accept(user:, account:, invitation:)

      return [ :err, invitation ] unless invitation.accepted?

      add_member(user:, workspace_uuid: account.uuid)

      notify_accepted(user:, invitation:)

      [ :ok, invitation ]
    rescue ActiveRecord::ActiveRecordError => e
      revert!(invitation:)

      [ :err, e ]
    end

    private

    def accept(user:, account:, invitation:)
      uuid, email, username = user.values_at(:uuid, :email, :username)

      Account.transaction do
        invitation.accept!

        self.person = Account::Person::Add.new(account:).call(uuid:, email:, username:)
      end
    end

    def add_member(user:, workspace_uuid:)
      uuid, email, username = user.values_at(:uuid, :email, :username)

      self.member = Workspace::Member::Add.new(workspace_uuid:).call(uuid:, email:, username:)
    end

    def notify_accepted(user:, invitation:)
      inviter = User.find_by!(uuid: invitation.invited_by.uuid)

      self.notification = User::Notification::Delivery.new(invitation).invitation_accepted(to: inviter)
    end

    def revert!(invitation:)
      undo(member) { Workspace::Member::Remove.call(uuid: member.uuid) }

      undo(person) { Account::Person::Remove.call(uuid: person.uuid, account: invitation.account) }

      invitation.revert!
    end
  end

  def perform(user:, invitation:) = Manager.new.call(user:, invitation:)
end
