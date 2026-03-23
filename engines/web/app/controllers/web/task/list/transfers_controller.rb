# frozen_string_literal: true

class Web::Task::List::TransfersController < Web::BaseController
  before_action :authenticate_user!, only: %i[new create]
  before_action :prepare_transfer!, only: %i[new create]

  def new
    @transfer = ::Workspace::List::Transfer.new

    render :new
  end

  def create
    case ::User::RequestListTransferProcess.perform_now(
      list: @transfer_task_list,
      from_workspace: current.workspace.record,
      initiated_by: current.workspace.member,
      to_email: params.dig(:workspace_list_transfer, :to_email)&.strip&.downcase
    )
    in [ :ok, transfer ]
      @transfer = transfer

      redirect_to task_list_path(@transfer_task_list), notice: "Transfer request sent to #{@transfer.list.name}."
    in [ :err, String => message ]
      redirect_to new_task_list_transfer_path(@transfer_task_list), alert: message
    in [ :err, transfer ]
      @transfer = transfer

      render :new, status: :unprocessable_entity
    end
  end

  private

  def prepare_transfer!
    set_transfer_task_list!
    return if performed?

    guard_transfer_owner_or_admin!
  end

  def set_transfer_task_list!
    raise ActiveRecord::RecordNotFound unless current.account
    @transfer_task_list = current.task_lists.find(params[:list_id])
    @task_list = @transfer_task_list
    true
  rescue ActiveRecord::RecordNotFound
    redirect_to home_path, alert: "List not found."
    false
  end

  def guard_transfer_owner_or_admin!
    return true if owner_or_admin?

    redirect_to home_path, alert: "Only owners and admins can transfer lists."
    false
  end
end
