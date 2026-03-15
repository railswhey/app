# frozen_string_literal: true

class Web::Task::List::TransfersController < Web::BaseController
  before_action :authenticate_user!, only: %i[new create]

  def new
    set_transfer_task_list! or return
    guard_transfer_owner_or_admin! or return
    @transfer = TaskListTransfer.new

    render :new
  end

  def create
    set_transfer_task_list! or return
    guard_transfer_owner_or_admin! or return

    to_email = params.dig(:task_list_transfer, :to_email)&.strip&.downcase
    to_user  = User.find_by(email: to_email)

    unless to_user
      redirect_to new_task_list_transfer_path(@transfer_task_list), alert: "No user found with that email."
      return
    end

    unless to_user.account
      redirect_to new_task_list_transfer_path(@transfer_task_list), alert: "Target user has no account."
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

      redirect_to task_list_path(@transfer_task_list), notice: "Transfer request sent to #{to_user.email}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_transfer_task_list!
    raise ActiveRecord::RecordNotFound unless Current.account
    @transfer_task_list = Current.account.task_lists.find(params[:list_id])
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
