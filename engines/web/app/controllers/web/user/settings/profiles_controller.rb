# frozen_string_literal: true

class Web::User::Settings::ProfilesController < Web::BaseController
  before_action :authenticate_user!

  def edit
    render :edit
  end

  def update
    if current.user.update(user_profile_params)
      redirect_to edit_user_settings_profile_path, notice: "Your profile has been updated."
    else
      render(:edit, status: :unprocessable_entity)
    end
  end

  private

  def user_profile_params
    @user_profile_params ||= params.require(:user).permit(:username)
  end
end
