# frozen_string_literal: true

class User::SignUpProcess < ApplicationJob
  Manager = Orchestrator.new(:user, :account, :workspace) do
    def call(params)
      register_user(params)

      return [ :err, user ] unless user.persisted?

      setup_account(user:)
      setup_workspace(user:)
      send_email_confirmation

      [ :ok, user ]
    rescue ActiveRecord::ActiveRecordError => e
      revert!

      [ :err, e ]
    end

    private

    def register_user(params)
      self.user = User::Registration.call(params)
    end

    def setup_account(user:)
      uuid, email, username = user.values_at(:uuid, :email, :username)

      self.account = Account::Setup.call(uuid:, email:, username:)
    end

    def setup_workspace(user:)
      uuid, email, username = user.values_at(:uuid, :email, :username)

      self.workspace = Workspace::Setup.call(uuid:, email:, username:)
    end

    def send_email_confirmation
      UserMailer.with(user:, token: user.generate_token_for(:email_confirmation))
                .email_confirmation.deliver_later
    end

    def revert!
      undo(workspace) { workspace.destroy! }
      undo(account)   { Account::Teardown.call(uuid: user.uuid) }

      user.destroy!
    end
  end

  def perform(...) = Manager.new.call(...)
end
