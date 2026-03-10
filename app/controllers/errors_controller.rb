# frozen_string_literal: true

class ErrorsController < ApplicationController
  before_action :try_resume_session

  ERRORS = {
    404 => { template: "errors/not_found", status: :not_found, message: "Not found" },
    422 => { template: "errors/unprocessable_entity", status: :unprocessable_entity, message: "Unprocessable entity" },
    500 => { template: "errors/internal_server_error", status: :internal_server_error, message: "Internal server error" }
  }.freeze

  def show
    error = ERRORS.fetch(params[:status].to_i, ERRORS[404])

    respond_to do |format|
      format.html { render error[:template], status: error[:status] }
      format.json do
        if error[:status] == :internal_server_error
          render(status: :internal_server_error, json: {
            status: :error, type: :object, data: { message: error[:message] }
          })
        else
          render_json_with_failure(status: error[:status], message: error[:message])
        end
      end
    end
  end

  private

  def try_resume_session
    current_member!
  rescue StandardError
    nil
  end
end
