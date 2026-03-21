# frozen_string_literal: true

class API::V1::Account::Transfers::ResponsesController < API::V1::BaseController
  before_action :current_member!
  before_action :load_transfer!

  rescue_from ActiveRecord::RecordNotFound do
    render_json_with_failure(status: :not_found, message: "Transfer not found.")
  end

  def show
    render :show
  end

  def update
    return render("errors/unauthorized", status: :unauthorized) unless Current.user

    unless @to_account&.owner_or_admin?(Current.user)
      render_json_with_failure(status: :forbidden, message: "Could not process transfer.")
      return
    end

    case User::RespondToTransferProcess.perform_now(
      transfer: @transfer,
      action: params[:action_type]
    )
    in [ :ok, _ ]
      render :show, status: :ok
    in [ :err, _ ]
      render_json_with_failure(status: :unprocessable_entity, message: "Could not process transfer.")
    end
  end

  private

  def load_transfer!
    @transfer     = Workspace::List::Transfer.find_by!(token: params[:token])
    @to_account   = Account.find_by(uuid: @transfer.to_workspace.uuid)
    @from_account = Account.find_by(uuid: @transfer.from_workspace.uuid)
  end
end
