# frozen_string_literal: true

class Web::Account::Transfers::ResponsesController < Web::BaseController
  before_action :current_member!
  before_action :load_transfer!

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to home_path, alert: "Transfer not found."
  end

  def show
    render :show
  end

  def update
    unless current.user
      redirect_to new_user_session_path(return_to: account_transfers_response_path(token: @transfer.token)),
                  notice: "Please sign in to respond to this transfer."
      return
    end

    unless @to_account&.owner_or_admin?(current.user)
      redirect_to account_transfers_response_path(token: @transfer.token), alert: "Could not process transfer."
      return
    end

    case ::User::RespondToTransferProcess.perform_now(
      transfer: @transfer,
      action: params[:action_type]
    )
    in [ :ok, _ ]
      msg = params[:action_type] == "accept" ? "List transferred successfully!" : "Transfer rejected."
      redirect_to home_path, notice: msg
    in [ :err, _ ]
      redirect_to account_transfers_response_path(token: @transfer.token),
                  alert: "Could not process transfer."
    end
  end

  private

  def load_transfer!
    @transfer     = ::Workspace::List::Transfer.find_by!(token: params[:token])
    @from_account = ::Account.find_by(uuid: @transfer.from_workspace.uuid)
    @to_account   = ::Account.find_by(uuid: @transfer.to_workspace.uuid)
  end
end
