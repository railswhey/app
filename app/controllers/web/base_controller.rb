# frozen_string_literal: true

class Web::BaseController < ApplicationController
  prepend_view_path Rails.root.join("app/views/web")

  private

  def authenticate_user!
    current_member!

    return if Current.user?

    alert, next_path =
      if current_user_id.present?
        [ "The page you are looking for does not exist, or you cannot access it.", home_path ]
      else
        [ "You need to sign in or sign up before continuing.", new_user_session_path ]
      end

    redirect_to next_path, alert:
  end

  def require_guest_access!
    current_member!

    return unless Current.user?

    redirect_to home_path, notice: "You are already signed in."
  end

  def current_member!
    task_list_id = params[:list_id]
    task_list_id = current_task_list_id if task_list_id.blank?

    Current.member!(user_id: current_user_id, account_id: session[:account_id], task_list_id:)

    if Current.user? && !Current.member?
      Current.member!(user_id: current_user_id, account_id: nil, task_list_id: nil)
    end

    session[:account_id] = Current.account_id if Current.member?
    self.current_task_list_id = Current.task_list_id if Current.member?
  end
end
