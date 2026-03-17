# frozen_string_literal: true

module User::PasswordReset
  def self.request(email:)
    user = User.find_by(email: email)

    return unless user

    UserMailer.with(user: user, token: user.generate_token_for(:reset_password)).reset_password.deliver_later
  end

  def self.find_by(token:)
    User.find_by_token_for(:reset_password, token)
  end
end
