# frozen_string_literal: true

class User::RegistrationsController < ApplicationController
  before_action :require_guest_access!, only: %i[new create]
  before_action :authenticate_user!, only: %i[destroy]

  def new
    @user = User.new

    render :new
  end

  def create
    @user = User.new(user_registration_params)

    respond_to do |format|
      if @user.save
        format.html do
          sign_in(@user)

          redirect_to(params[:return_to].presence || task_list_items_path(Current.task_list_id), notice: "You have successfully registered!")
        end
        format.json { render "user/settings/tokens/show", status: :created }
      else
        format.html { render(:new, status: :unprocessable_entity) }
        format.json { render("errors/from_model", status: :unprocessable_entity, locals: { model: @user }) }
      end
    end
  end

  def destroy
    Current.user.destroy!

    respond_to do |format|
      format.html do
        sign_out
        redirect_to root_path, notice: "Your account has been deleted."
      end
      format.json { head :no_content }
    end
  end

  private

  def user_registration_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation)
  end
end
