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

  include TaskListsTransfersConcern
  include TaskListsCommentsConcern

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

  private

  def set_task_list
    @task_list = Current.task_lists.find(params[:id])
  end

  def task_list_params
    params.require(:task_list).permit(:name, :description)
  end
end
