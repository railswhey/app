# frozen_string_literal: true

class Web::BaseController < ActionController::Base
  include Web::Engine.routes.url_helpers

  helper Web::Engine.routes.url_helpers
  prepend_view_path Web::Engine.root.join("app/views")
  prepend_view_path Web::Engine.root.join("app/views/web")

  layout "application"

  allow_browser versions: :modern, unless: -> { Rails.env.local? }

  private

  helper_method def current
    Web::Current
  end

  def home_path
    current.task_list_id? ? task_list_items_path(current.task_list_id) : task_lists_path
  end
  helper_method :home_path

  def current_user_id=(id)
    session[:user_id] = id
  end

  def current_account_id=(id)
    session[:account_id] = id
  end

  def current_task_list_id=(id)
    session[:task_list_id] = id
  end

  def current_user_id      = session[:user_id]
  def current_account_id   = session[:account_id]
  def current_task_list_id = session[:task_list_id]

  def sign_in(user)
    sign_out

    self.current_user_id = user.id

    current_member!
  end

  def sign_out
    current.reset

    reset_session
  end

  def owner_or_admin?
    current.owner_or_admin?
  end

  def authenticate_user!
    current_member!

    return if current.user?

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

    return unless current.user?

    redirect_to home_path, notice: "You are already signed in."
  end

  def current_member!
    task_list_id = params[:list_id].presence || current_task_list_id

    current.authorize!(user_id: current_user_id, account_id: current_account_id, task_list_id:)

    current.authorize!(user_id: current_user_id) if current.user? && !current.authorized?

    if current.authorized?
      self.current_account_id = current.account_id
      self.current_task_list_id = current.task_list_id
    end
  end
end
