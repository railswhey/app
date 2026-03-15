# frozen_string_literal: true

class API::V1::User::RegistrationsController < API::V1::BaseController
  before_action :authenticate_user!, only: %i[destroy]

  def create
    @user = User.new(user_registration_params)

    if @user.save
      render "api/v1/user/settings/tokens/show", status: :created
    else
      render("errors/from_model", status: :unprocessable_entity, locals: { model: @user })
    end
  end

  def destroy
    Current.user.destroy!

    head :no_content
  end

  private

  def user_registration_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation)
  end
end
