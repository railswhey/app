# frozen_string_literal: true

class API::V1::User::Settings::ProfilesController < API::V1::BaseController
  before_action :authenticate_user!

  def update
    if current.user.update(user_profile_params)
      render(status: :ok, json: { status: :success, type: :object, data: {} })
    else
      message = current.user.errors.full_messages.join(", ")
      details = current.user.errors.to_hash

      render_json_with_failure(status: :unprocessable_entity, message:, details:)
    end
  end

  private

  def user_profile_params
    @user_profile_params ||= params.require(:user).permit(:username)
  end
end
