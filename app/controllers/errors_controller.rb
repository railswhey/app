# frozen_string_literal: true

class ErrorsController < ApplicationController
  before_action :try_resume_session

  def not_found
    respond_to do |format|
      format.html { render status: :not_found }
      format.json { render_json_with_failure(status: :not_found, message: "Not found") }
    end
  end

  def unprocessable_entity
    respond_to do |format|
      format.html { render status: :unprocessable_entity }
      format.json { render_json_with_failure(status: :unprocessable_entity, message: "Unprocessable entity") }
    end
  end

  def internal_server_error
    respond_to do |format|
      format.html { render status: :internal_server_error }
      format.json do
        render(status: :internal_server_error, json: {
          status: :error, type: :object, data: { message: "Internal server error" }
        })
      end
    end
  end

  private

  # Optionally load the session so Current.user is available in the layout
  # (e.g. navigation links) without enforcing authentication.
  def try_resume_session
    current_member!
  rescue StandardError
    nil
  end
end
