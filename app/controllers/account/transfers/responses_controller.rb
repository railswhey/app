# frozen_string_literal: true

class Account::Transfers::ResponsesController < ApplicationController
  def show
    current_member!
    @transfer = TaskListTransfer.find_by!(token: params[:token])

    render :show
  rescue ActiveRecord::RecordNotFound
    if request.format.json?
      render_json_with_failure(status: :not_found, message: "Transfer not found.")
    else
      redirect_to home_path, alert: "Transfer not found."
    end
  end

  def update
    current_member!
    @transfer = TaskListTransfer.find_by!(token: params[:token])

    unless Current.user
      if request.format.json?
        render("errors/unauthorized", status: :unauthorized)
      else
        redirect_to new_user_session_path(return_to: account_transfers_response_path(token: @transfer.token)),
                    notice: "Please sign in to respond to this transfer."
      end
      return
    end

    action = params[:action_type]
    success = case action
    when "accept" then @transfer.accept!(Current.user)
    when "reject" then @transfer.reject!(Current.user)
    else false
    end

    if success
      respond_to do |format|
        msg = action == "accept" ? "List transferred successfully!" : "Transfer rejected."
        format.html { redirect_to home_path, notice: msg }
        format.json { render :show, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to account_transfers_response_path(token: @transfer.token), alert: "Could not process transfer." }
        format.json { render_json_with_failure(status: :unprocessable_entity, message: "Could not process transfer.") }
      end
    end
  rescue ActiveRecord::RecordNotFound
    if request.format.json?
      render_json_with_failure(status: :not_found, message: "Transfer not found.")
    else
      redirect_to home_path, alert: "Transfer not found."
    end
  end
end
