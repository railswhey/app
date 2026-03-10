# frozen_string_literal: true

class UserRegistrationsController < ApplicationController
  before_action :require_guest_access!

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

          redirect_to(params[:return_to].presence || task_list_task_items_path(Current.task_list_id), notice: "You have successfully registered!")
        end
        format.json { render "user_tokens/show", status: :created }
      else
        format.html { render(:new, status: :unprocessable_entity) }
        format.json { render("errors/from_model", status: :unprocessable_entity, locals: { model: @user }) }
      end
    end
  end

  private

  def user_registration_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation)
  end
end
