# frozen_string_literal: true

class Web::User::PasswordsController < Web::BaseController
  before_action :require_guest_access!, only: %i[new create]
  before_action :set_user_by_token, only: %i[edit update]

  def new
    @user = User.new

    render :new
  end

  def create
    User::PasswordReset.request(email: params.require(:user).require(:email))

    redirect_to new_user_session_path, notice: "Check your email to reset your password."
  end

  def edit
    @token = params[:token]
    render :edit
  end

  def update
    @user.assign_attributes(user_password_params)
    @user.errors.add(:password, :blank) if user_password_params[:password].blank?

    if @user.errors.none? && @user.save
      redirect_to new_user_session_path, notice: "Your password has been reset successfully. Please sign in."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user_by_token
    @user = User::PasswordReset.find_by(token: params[:token])

    return if @user

    redirect_to new_user_password_path, alert: "Invalid or expired token."
  end

  def user_password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
