# frozen_string_literal: true

class TaskListsController < ApplicationController
  before_action :authenticate_user!, except: %i[show_transfer update_transfer]
  before_action :set_task_list, except: %i[index new create new_transfer create_transfer show_transfer update_transfer create_comment edit_comment update_comment destroy_comment]
  before_action only: [ :edit, :update, :destroy ], if: -> { @task_list.inbox? } do
    if request.format.json?
      render_json_with_failure(status: :forbidden, message: "Inbox cannot be updated or deleted")
    else
      redirect_to task_lists_url, alert: "You cannot edit or delete the inbox."
    end
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    raise exception unless request.format.json?

    render_json_with_failure(status: :not_found, message: "Task list not found")
  end

  def index
    @task_lists = Current.task_lists
  end

  def show
    items               = @task_list.task_items
    @items_total        = items.count
    @items_done         = items.completed.count
    @items_pending      = @items_total - @items_done
    @items_pct          = @items_total > 0 ? (@items_done * 100.0 / @items_total).round : 0
    @preview_items      = items.incomplete.order(created_at: :desc).limit(5).includes(:assigned_user)
    @list_comments      = @task_list.comments.chronological.includes(:user)
  end

  def new
    @task_list = Current.task_lists.new
  end

  def edit
  end

  def create
    @task_list = Current.task_lists.new(task_list_params)

    respond_to do |format|
      if @task_list.save
        format.html { redirect_to task_list_url(@task_list), notice: "Task list was successfully created." }
        format.json { render :show, status: :created, location: @task_list }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render_json_with_model_failure(@task_list) }
      end
    end
  end

  def update
    respond_to do |format|
      if @task_list.update(task_list_params)
        format.html { redirect_to task_list_url(@task_list), notice: "Task list was successfully updated." }
        format.json { render :show, status: :ok, location: @task_list }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render_json_with_model_failure(@task_list) }
      end
    end
  end

  def destroy
    @task_list.destroy!

    respond_to do |format|
      format.html do
        inbox = Current.account.task_lists.inbox.first
        self.current_task_list_id = inbox&.id

        redirect_to task_list_task_items_path(inbox), notice: "Task list was successfully destroyed."
      end
      format.json { head :no_content }
    end
  end

  def new_transfer
    set_transfer_task_list! or return
    guard_transfer_owner_or_admin! or return
    @transfer = TaskListTransfer.new

    render :new_transfer
  end

  def create_transfer
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
      TransferMailer.transfer_requested(@transfer).deliver_later

      respond_to do |format|
        format.html { redirect_to task_list_path(@transfer_task_list), notice: "Transfer request sent to #{to_user.email}." }
        format.json { render :show_transfer, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new_transfer, status: :unprocessable_entity }
        format.json { render_json_with_model_failure(@transfer) }
      end
    end
  end

  def show_transfer
    current_member!
    @transfer = TaskListTransfer.find_by!(token: params[:token])

    render :show_transfer
  rescue ActiveRecord::RecordNotFound
    if request.format.json?
      render_json_with_failure(status: :not_found, message: "Transfer not found.")
    else
      redirect_to home_path, alert: "Transfer not found."
    end
  end

  def update_transfer
    current_member!
    @transfer = TaskListTransfer.find_by!(token: params[:token])

    unless Current.user
      if request.format.json?
        render("errors/unauthorized", status: :unauthorized)
      else
        redirect_to new_session_users_path(return_to: show_task_list_transfer_path(@transfer.token)),
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
        format.json { render :show_transfer, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to show_task_list_transfer_path(@transfer.token), alert: "Could not process transfer." }
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

  def create_comment
    @task_list = Current.task_lists.find(params[:task_list_id])
    @comment = @task_list.comments.new(comment_params)
    @comment.user = Current.user

    if @comment.save
      redirect_to task_list_path(@task_list), notice: "Comment added."
    else
      redirect_to task_list_path(@task_list), alert: @comment.errors.full_messages.to_sentence
    end
  end

  def edit_comment
    @task_list = Current.task_lists.find(params[:task_list_id])
    @comment = @task_list.comments.find(params[:id])
    require_comment_author! or return

    render "shared/comments/edit"
  end

  def update_comment
    @task_list = Current.task_lists.find(params[:task_list_id])
    @comment = @task_list.comments.find(params[:id])
    require_comment_author! or return

    if @comment.update(comment_params)
      redirect_to task_list_path(@task_list), notice: "Comment updated."
    else
      render "shared/comments/edit", status: :unprocessable_entity
    end
  end

  def destroy_comment
    @task_list = Current.task_lists.find(params[:task_list_id])
    @comment = @task_list.comments.find(params[:id])
    require_comment_author! or return

    @comment.destroy!
    redirect_to task_list_path(@task_list), notice: "Comment deleted."
  end

  private

  def set_task_list
    @task_list = Current.task_lists.find(params[:id])
  end

  def require_comment_author!
    return true if @comment.user_id == Current.user.id

    redirect_to task_list_path(@task_list), alert: "You can only modify your own comments."
    false
  end

  def comment_params
    params.require(:comment).permit(:body)
  end

  def set_transfer_task_list!
    raise ActiveRecord::RecordNotFound unless Current.account
    @transfer_task_list = Current.account.task_lists.find(params[:task_list_id])
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

  def task_list_params
    params.require(:task_list).permit(:name, :description)
  end
end
