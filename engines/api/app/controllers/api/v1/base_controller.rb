# frozen_string_literal: true

class API::V1::BaseController < ActionController::Base
  include ActionController::HttpAuthentication::Token::ControllerMethods
  include API::Engine.routes.url_helpers

  helper API::Engine.routes.url_helpers
  prepend_view_path API::Engine.root.join("app/views")
  prepend_view_path API::Engine.root.join("app/views/api/v1")

  skip_forgery_protection

  prepend_before_action do
    request.format = :json
  end

  rescue_from ActionController::ParameterMissing do |exception|
    render_json_with_failure(status: :bad_request, message: exception.message)
  end

  private

  helper_method def current
    API::Current
  end

  def owner_or_admin?
    current.owner_or_admin?
  end

  def authenticate_user!
    current_member!

    return if current.user?

    render_json_with_failure(status: :unauthorized, message: "Invalid API token")
  end

  def current_member!
    authenticate_with_http_token do |user_token|
      current.authorize!(user_token:, task_list_id: params[:list_id])
    end
  end

  def render_json_with_model_failure(record)
    message = record.errors.full_messages.join(", ")
    details = record.errors.messages

    render_json_with_failure(status: :unprocessable_entity, message:, details:)
  end

  def render_json_with_failure(status:, message:, details: {})
    render(status:, json: { status: :failure, type: :object, data: { message:, details: } })
  end
end
