# frozen_string_literal: true

class API::V1::ErrorsController < API::V1::BaseController
  ERRORS = {
    404 => { status: :not_found, message: "Not found" },
    422 => { status: :unprocessable_entity, message: "Unprocessable entity" },
    500 => { status: :internal_server_error, message: "Internal server error" }
  }.freeze

  def show
    error = ERRORS.fetch(params[:status].to_i, ERRORS[404])

    if error[:status] == :internal_server_error
      render(status: :internal_server_error, json: {
        status: :error, type: :object, data: { message: error[:message] }
      })
    else
      render_json_with_failure(status: error[:status], message: error[:message])
    end
  end
end
