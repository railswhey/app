# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ActionController::HttpAuthentication::Token::ControllerMethods

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern, unless: -> { Rails.env.local? }

  private

  def home_path
    Current.task_list_id? ? task_list_items_path(Current.task_list_id) : task_lists_path
  end
  helper_method :home_path

  def current_user_id=(id)
    session[:user_id] = id
  end

  def current_user_id
    session[:user_id]
  end

  def current_task_list_id=(id)
    session[:task_list_id] = id
  end

  def current_task_list_id
    session[:task_list_id]
  end

  def sign_in(user)
    sign_out

    self.current_user_id = user.id

    current_member!
  end

  def sign_out
    Current.reset

    reset_session
  end

  def owner_or_admin?
    Current.owner_or_admin?
  end
end
