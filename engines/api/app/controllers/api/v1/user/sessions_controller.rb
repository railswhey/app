# frozen_string_literal: true

class API::V1::User::SessionsController < API::V1::BaseController
  def create
    @user = ::User.authenticate_by(user_session_params)

    if @user
      render "user/settings/tokens/show", status: :ok
    else
      render("errors/unauthorized", status: :unauthorized, locals: {
        message: "Invalid email or password. Please try again."
      })
    end
  end

  private

  def user_session_params
    params.require(:user).permit(:email, :password)
  end
end
