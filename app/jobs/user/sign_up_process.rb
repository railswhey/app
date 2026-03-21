# frozen_string_literal: true

class User::SignUpProcess < ApplicationJob
  def perform(params)
    user = nil

    ActiveRecord::Base.transaction do
      user = User::Registration.call(params)

      if user.persisted?
        uuid, email, username = user.values_at(:uuid, :email, :username)

        Account::Setup.call(uuid:, email:, username:)

        Workspace::Setup.call(uuid:, email:, username:)
      end
    end

    if user.persisted?
      UserMailer.with(user:, token: user.generate_token_for(:email_confirmation))
                .email_confirmation.deliver_later
    end

    user.persisted? ? [ :ok, user ] : [ :err, user ]
  end
end
