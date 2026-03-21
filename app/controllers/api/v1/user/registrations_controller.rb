# frozen_string_literal: true

class API::V1::User::RegistrationsController < API::V1::BaseController
  before_action :authenticate_user!, only: %i[destroy]

  def create
    case User::SignUpProcess.perform_now(user_registration_params)
    in [ :ok, user ]
      @user = user

      render "api/v1/user/settings/tokens/show", status: :created
    in [ :err, user ]
      render("errors/from_model", status: :unprocessable_entity, locals: { model: user })
    end
  end

  def destroy
    case Account::CloseProcess.perform_now(Current.user)
    in [ :ok, _ ]
      head :no_content
    end
  end

  private

  def user_registration_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation)
  end
end
