# frozen_string_literal: true

class Web::ErrorsController < Web::BaseController
  before_action :try_resume_session

  ERRORS = {
    404 => { template: "not_found", status: :not_found },
    422 => { template: "unprocessable_entity", status: :unprocessable_entity },
    500 => { template: "internal_server_error", status: :internal_server_error }
  }.freeze

  def show
    error = ERRORS.fetch(params[:status].to_i, ERRORS[404])
    render error[:template], status: error[:status]
  end

  private

  def try_resume_session
    current_member!
  rescue StandardError
    nil
  end
end
