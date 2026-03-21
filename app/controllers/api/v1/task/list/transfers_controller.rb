# frozen_string_literal: true

class API::V1::Task::List::TransfersController < API::V1::BaseController
  before_action :authenticate_user!
  before_action :prepare_transfer!

  def create
    case User::RequestListTransferProcess.perform_now(
      list: @task_list,
      from_workspace: Current.workspace.record,
      initiated_by: Current.workspace.member,
      to_email: params.dig(:workspace_list_transfer, :to_email)&.strip&.downcase
    )
    in [ :ok, transfer ]
      @transfer = transfer

      render :show, status: :created
    in [ :err, String ]
      render_json_with_failure(status: :unprocessable_entity, message: "Recipient not found or has no account.")
    in [ :err, transfer ]
      render_json_with_model_failure(transfer)
    end
  end

  private

  def prepare_transfer!
    set_transfer_task_list!

    return if performed?

    guard_transfer_owner_or_admin!
  end

  def set_transfer_task_list!
    raise ActiveRecord::RecordNotFound unless Current.account

    @task_list = Current.task_lists.find(params[:list_id])

    true
  rescue ActiveRecord::RecordNotFound
    render_json_with_failure(status: :not_found, message: "Task list not found.")

    false
  end

  def guard_transfer_owner_or_admin!
    return true if owner_or_admin?

    render_json_with_failure(status: :forbidden, message: "Only owners and admins can transfer lists.")

    false
  end
end
