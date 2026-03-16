# frozen_string_literal: true

class API::V1::User::PasswordsController < API::V1::BaseController
  before_action :set_user_by_token, only: %i[update]

  def create
    User.send_reset_password_email(params.require(:user).require(:email))

    render(status: :ok, json: { status: :success, type: :object, data: {} })
  end

  def update
    @user.assign_attributes(user_password_params)
    @user.errors.add(:password, :blank) if user_password_params[:password].blank?

    if @user.errors.none? && @user.save
      render(status: :ok, json: { status: :success, type: :object, data: {} })
    else
      render("errors/from_model", status: :unprocessable_entity, locals: { model: @user })
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_reset_password_token(params[:token])

    return if @user

    render("errors/response", status: :unprocessable_entity, locals: { message: "Invalid token" })
  end

  def user_password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
