# frozen_string_literal: true

class Web::User::Settings::PasswordsController < Web::BaseController
  before_action :authenticate_user!

  def update
    user_password_params[:password_challenge] = user_password_params.delete(:current_password) if user_password_params.key?(:current_password)

    if current.user.update(user_password_params)
      redirect_to edit_user_settings_profile_path, notice: "Your password has been updated."
    else
      render "user/settings/profiles/edit", status: :unprocessable_entity
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
