# frozen_string_literal: true

class User::Settings::ProfilesController < ApplicationController
  before_action :authenticate_user!

  def edit
    render :edit
  end

  def update
    respond_to do |format|
      if Current.user.update(user_profile_params)
        format.html { redirect_to edit_user_settings_profile_path, notice: "Your profile has been updated." }
        format.json { render(status: :ok, json: { status: :success, type: :object, data: {} }) }
      else
        format.html { render(:edit, status: :unprocessable_entity) }
        format.json do
          message = Current.user.errors.full_messages.join(", ")
          render_json_with_failure(status: :unprocessable_entity, message:, details: Current.user.errors.to_hash)
        end
      end
    end
  end

  private

  def user_profile_params
    @user_profile_params ||= params.require(:user).permit(:username)
  end
end
