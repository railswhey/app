# frozen_string_literal: true

class API::V1::Task::List::TransfersController < API::V1::BaseController
  before_action :authenticate_user!

  def create
    set_transfer_task_list! or return
    guard_transfer_owner_or_admin! or return

    to_user, error = TaskListTransfer.resolve_recipient(params.dig(:task_list_transfer, :to_email))

    if error
      render_json_with_failure(status: :unprocessable_entity, message: error)
      return
    end

    @transfer = TaskListTransfer.new(
      task_list:      @transfer_task_list,
      from_account:   Current.account,
      to_account:     to_user.account,
      transferred_by: Current.user
    )

    if @transfer.save
      Notification.create!(user: to_user, notifiable: @transfer, action: "transfer_requested")
      Task::ListTransferMailer.transfer_requested(@transfer).deliver_later

      render :show, status: :created
    else
      render_json_with_model_failure(@transfer)
    end
  end

  private

  def set_transfer_task_list!
    raise ActiveRecord::RecordNotFound unless Current.account
    @transfer_task_list = Current.account.task_lists.find(params[:list_id])
    @task_list = @transfer_task_list
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
