# frozen_string_literal: true

class Web::User::PasswordsController < Web::BaseController
  before_action :require_guest_access!, only: %i[new create]
  before_action :set_user_by_token, only: %i[edit update]

  def new
    @user = User.new

    render :new
  end

  def create
    user = User.find_by(email: params.require(:user).require(:email))

    if user
      UserMailer.with(
        user: user,
        token: user.generate_token_for(:reset_password)
      ).reset_password.deliver_later
    end

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
    @user = User.find_by_token_for(:reset_password, params[:token])

    return if @user

    redirect_to new_user_password_path, alert: "Invalid or expired token."
  end

  def user_password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
