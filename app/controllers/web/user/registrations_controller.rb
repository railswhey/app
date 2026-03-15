# frozen_string_literal: true

class Web::User::RegistrationsController < Web::BaseController
  before_action :require_guest_access!, only: %i[new create]
  before_action :authenticate_user!, only: %i[destroy]

  def new
    @user = User.new

    render :new
  end

  def create
    @user = User.new(user_registration_params)

    if @user.save
      sign_in(@user)

      redirect_to(params[:return_to].presence || task_list_items_path(Current.task_list_id), notice: "You have successfully registered!")
    else
      render(:new, status: :unprocessable_entity)
    end
  end

  def destroy
    Current.user.destroy!

    sign_out
    redirect_to root_path, notice: "Your account has been deleted."
  end

  private

  def user_registration_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation)
  end
end
