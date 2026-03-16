# frozen_string_literal: true

class API::V1::Account::Transfers::ResponsesController < API::V1::BaseController
  rescue_from ActiveRecord::RecordNotFound do
    render_json_with_failure(status: :not_found, message: "Transfer not found.")
  end

  def show
    current_member!
    @transfer = Task::List::Transfer.find_by!(token: params[:token])

    render :show
  end

  def update
    current_member!
    @transfer = Task::List::Transfer.find_by!(token: params[:token])

    unless Current.user
      render("errors/unauthorized", status: :unauthorized)
      return
    end

    action = params[:action_type]
    success = case action
    when "accept" then @transfer.accept!(Current.user)
    when "reject" then @transfer.reject!(Current.user)
    else false
    end

    if success
      render :show, status: :ok
    else
      render_json_with_failure(status: :unprocessable_entity, message: "Could not process transfer.")
    end
  end
end
