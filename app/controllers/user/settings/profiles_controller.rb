# frozen_string_literal: true

class User::Settings::ProfilesController < ApplicationController
  before_action :authenticate_user!

  def edit
    render :edit
  end

  def update
    user_profile_params[:password_challenge] = user_profile_params.delete(:current_password) if user_profile_params.key?(:current_password)

    respond_to do |format|
      if Current.user.update(user_profile_params)
        format.html { redirect_to edit_user_settings_profile_path, notice: "Your password has been updated." }
        format.json { render(status: :ok, json: { status: :success, type: :object, data: {} }) }
      else
        format.html { render(:edit, status: :unprocessable_entity) }
        format.json do
          message = Current.user.errors.full_messages.join(", ")
          message.gsub!("Password challenge", "Current password")

          details = Current.user.errors.to_hash
          details[:current_password] = details.delete(:password_challenge) if details[:password_challenge]

          render_json_with_failure(status: :unprocessable_entity, message:, details:)
        end
      end
    end
  end

  private

  def user_profile_params
    @user_profile_params ||= params.require(:user).permit(
      :username,
      :current_password,
      :password,
      :password_confirmation,
      :password_challenge
    ).with_defaults(password_challenge: "")
  end
end
