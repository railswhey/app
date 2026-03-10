# frozen_string_literal: true

class UserSessionsController < ApplicationController
  before_action :require_guest_access!, only: %i[new create]
  before_action :authenticate_user!, only: %i[destroy]

  def new
    @user = User.new

    render :new
  end

  def create
    @user = User.authenticate_by(user_session_params)

    respond_to do |format|
      if @user
        format.html do
          sign_in(@user)

          redirect_to(params[:return_to].presence || task_list_task_items_path(Current.task_list_id), notice: "You have successfully signed in!")
        end
        format.json { render "user_tokens/show", status: :ok }
      else
        format.html do
          flash.now[:alert] = "Invalid email or password. Please try again."

          @user = User.new(email: user_session_params[:email])

          render :new, status: :unprocessable_entity
        end
        format.json do
          render("errors/unauthorized", status: :unauthorized, locals: {
            message: "Invalid email or password. Please try again."
          })
        end
      end
    end
  end

  def destroy
    sign_out

    redirect_to new_user_session_path, notice: "You have successfully signed out."
  end

  private

  def user_session_params
    params.require(:user).permit(:email, :password)
  end
end
