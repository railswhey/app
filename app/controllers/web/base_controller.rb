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
    task_list_id = params[:list_id].presence || current_task_list_id

    Current.authorize!(user_id: current_user_id, account_id: current_account_id, task_list_id:)

    Current.authorize!(user_id: current_user_id) if Current.user? && !Current.authorized?

    if Current.authorized?
      self.current_account_id = Current.account_id
      self.current_task_list_id = Current.task_list_id
    end
  end
end
