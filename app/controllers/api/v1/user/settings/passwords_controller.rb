# frozen_string_literal: true

class API::V1::User::Settings::PasswordsController < API::V1::BaseController
  before_action :authenticate_user!

  def update
    user_password_params[:password_challenge] = user_password_params.delete(:current_password) if user_password_params.key?(:current_password)

    if Current.user.update(user_password_params)
      render(status: :ok, json: { status: :success, type: :object, data: {} })
    else
      message = Current.user.errors.full_messages.join(", ")
      message.gsub!("Password challenge", "Current password")

      details = Current.user.errors.to_hash
      details[:current_password] = details.delete(:password_challenge) if details[:password_challenge]

      render_json_with_failure(status: :unprocessable_entity, message:, details:)
    end
  end

  private

  def user_password_params
    @user_password_params ||= params.require(:user).permit(
      :current_password,
      :password,
      :password_confirmation,
      :password_challenge
    ).with_defaults(password_challenge: "")
  end
end
