# frozen_string_literal: true

class Web::Account::Transfers::ResponsesController < Web::BaseController
  def show
    current_member!
    @transfer = Task::List::Transfer.find_by!(token: params[:token])

    render :show
  rescue ActiveRecord::RecordNotFound
    redirect_to home_path, alert: "Transfer not found."
  end

  def update
    current_member!
    @transfer = Task::List::Transfer.find_by!(token: params[:token])

    unless Current.user
      redirect_to new_user_session_path(return_to: account_transfers_response_path(token: @transfer.token)),
                  notice: "Please sign in to respond to this transfer."
      return
    end

    action = params[:action_type]
    success = case action
    when "accept" then @transfer.accept!(Current.user)
    when "reject" then @transfer.reject!(Current.user)
    else false
    end

    if success
      msg = action == "accept" ? "List transferred successfully!" : "Transfer rejected."
      redirect_to home_path, notice: msg
    else
      redirect_to account_transfers_response_path(token: @transfer.token), alert: "Could not process transfer."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to home_path, alert: "Transfer not found."
  end
end
