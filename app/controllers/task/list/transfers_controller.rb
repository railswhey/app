# frozen_string_literal: true

class Task::List::TransfersController < ApplicationController
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
      if request.format.json?
        render_json_with_failure(status: :unprocessable_entity, message: "No user found with that email.")
      else
        redirect_to new_task_list_transfer_path(@transfer_task_list), alert: "No user found with that email."
      end
      return
    end

    unless to_user.account
      if request.format.json?
        render_json_with_failure(status: :unprocessable_entity, message: "Target user has no account.")
      else
        redirect_to new_task_list_transfer_path(@transfer_task_list), alert: "Target user has no account."
      end
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

      respond_to do |format|
        format.html { redirect_to task_list_path(@transfer_task_list), notice: "Transfer request sent to #{to_user.email}." }
        format.json { render :show, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render_json_with_model_failure(@transfer) }
      end
    end
  end

  private

  def set_transfer_task_list!
    raise ActiveRecord::RecordNotFound unless Current.account
    @transfer_task_list = Current.account.task_lists.find(params[:list_id])
    @task_list = @transfer_task_list
    true
  rescue ActiveRecord::RecordNotFound
    if request.format.json?
      render_json_with_failure(status: :not_found, message: "Task list not found.")
    else
      redirect_to home_path, alert: "List not found."
    end
    false
  end

  def guard_transfer_owner_or_admin!
    return true if Current.account.memberships.owner_or_admin.exists?(user: Current.user)

    if request.format.json?
      render_json_with_failure(status: :forbidden, message: "Only owners and admins can transfer lists.")
    else
      redirect_to home_path, alert: "Only owners and admins can transfer lists."
    end
    false
  end
end
