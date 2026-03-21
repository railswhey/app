# frozen_string_literal: true

class User::SignUpProcess < ApplicationJob
  Manager = Struct.new(:user) do
    def call(params)
      ActiveRecord::Base.transaction do
        register_user(params)

        setup_account_and_workspace if user.persisted?
      end

      send_email_confirmation if user.persisted?

      user.persisted? ? [ :ok, user ] : [ :err, user ]
    end

    private

    def register_user(params)
      self.user = User::Registration.call(params)
    end

    def setup_account_and_workspace
      uuid, email, username = user.values_at(:uuid, :email, :username)

      Account::Setup.call(uuid:, email:, username:)

      Workspace::Setup.call(uuid:, email:, username:)
    end

    def send_email_confirmation
      UserMailer.with(user:, token: user.generate_token_for(:email_confirmation))
                .email_confirmation.deliver_later
    end
  end

  def perform(...) = Manager.new.call(...)
end
