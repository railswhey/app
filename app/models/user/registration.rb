# frozen_string_literal: true

class User::Registration
  attr_reader :user

  def initialize(user = User.new)
    @user = user
  end

  def create(params)
    user.assign_attributes(params)

    return user unless user.valid?

    user.transaction do
      user
        .tap(&:save!)
        .tap(&:create_token!)
        .then { Account::Workspace.for!(it) }
    end

    UserMailer.with(user:, token: user.generate_token_for(:email_confirmation))
              .email_confirmation.deliver_later

    user
  rescue ActiveRecord::RecordInvalid
    user
  end

  def destroy
    return user if user.new_record?

    user.transaction do
      user.account.destroy!
      user.destroy!
    end

    user
  end
end
