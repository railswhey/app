# frozen_string_literal: true

class TaskItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_task_list!, except: %i[my_tasks create_comment edit_comment update_comment destroy_comment]
  before_action :set_task_item, except: %i[index new create my_tasks create_comment edit_comment update_comment destroy_comment]

  rescue_from ActiveRecord::RecordNotFound do |exception|
    raise exception unless request.format.json?

    render_json_with_failure(status: :not_found, message: "Task list or item not found")
  end

  def index
    task_items = Current.task_items

    @task_items =
      case params[:filter]
      when "completed" then task_items.completed.order(completed_at: :desc)
      when "incomplete" then task_items.incomplete.order(created_at: :desc)
      else task_items.order(Arel.sql("task_items.completed_at DESC NULLS FIRST, task_items.created_at DESC"))
      end
  end

  def show
  end

  def new
    @task_item = Current.task_items.new
  end

  def edit
  end

  def create
    @task_item = Current.task_items.new(task_item_params)

    respond_to do |format|
      if @task_item.save
        format.html do
          redirect_to(next_location, notice: "Task item was successfully created.")
        end
        format.json do
          render :show, status: :created, location: task_item_url(@task_item)
        end
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render_json_with_model_failure(@task_item) }
      end
    end
  end

  def update
    respond_to do |format|
      if @task_item.update(task_item_params)
        format.html do
          redirect_to(next_location, notice: "Task item was successfully updated.")
        end
        format.json { render :show, status: :ok, location: task_item_url(@task_item) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render_json_with_model_failure(@task_item) }
      end
    end
  end

  def destroy
    @task_item.destroy!

    respond_to do |format|
      format.html do
        redirect_to(next_location, notice: "Task item was successfully destroyed.")
      end
      format.json { head :no_content }
    end
  end

  def complete
    @task_item.complete!

    respond_to do |format|
      format.html do
        redirect_to(next_location, notice: "Task item was successfully marked as completed.")
      end
      format.json { render :show, status: :ok, location: task_item_url(@task_item) }
    end
  end

  def incomplete
    @task_item.incomplete!

    respond_to do |format|
      format.html do
        redirect_to(next_location, notice: "Task item was successfully marked as incomplete.")
      end
      format.json { render :show, status: :ok, location: task_item_url(@task_item) }
    end
  end

  def move
    source_list = @task_list
    target_list = Current.account.task_lists.find_by(id: params[:target_list_id])

    unless target_list
      respond_to do |format|
        format.html { redirect_to task_list_task_items_path(source_list), alert: "Target list not found." }
        format.json { render_json_with_failure(status: :unprocessable_entity, message: "Target list not found.") }
      end
      return
    end

    if target_list == source_list
      respond_to do |format|
        format.html { redirect_to task_list_task_items_path(source_list), alert: "Task is already in that list." }
        format.json { render_json_with_failure(status: :unprocessable_entity, message: "Task is already in that list.") }
      end
      return
    end

    @task_item.update!(task_list: target_list)

    respond_to do |format|
      format.html { redirect_to task_list_task_items_path(source_list), notice: "\"#{@task_item.name}\" moved to \"#{target_list.name}\"." }
      format.json { render :show, status: :ok, location: task_list_task_item_url(target_list, @task_item) }
    end
  end

  def my_tasks
    @filter = params[:filter]
    items = TaskItem
      .joins(:task_list)
      .where(task_lists: { account_id: Current.account_id })
      .where(assigned_user_id: Current.user.id)

    @task_items = case @filter
    when "completed"  then items.completed
    when "incomplete" then items.incomplete
    else items
    end.order(created_at: :desc).limit(100).includes(:task_list)

    @item_counts = {
      all:        items.count,
      incomplete: items.incomplete.count,
      completed:  items.completed.count
    }

    respond_to do |format|
      format.html { render :my_tasks }
      format.json { render :my_tasks }
    end
  end

  def create_comment
    @task_list = Current.account.task_lists.find(params[:task_list_id])
    @task_item = @task_list.task_items.find(params[:task_item_id])
    @comment = @task_item.comments.new(comment_params)
    @comment.user = Current.user

    if @comment.save
      redirect_to task_list_task_item_path(@task_list, @task_item), notice: "Comment added."
    else
      redirect_to task_list_task_item_path(@task_list, @task_item), alert: @comment.errors.full_messages.to_sentence
    end
  end

  def edit_comment
    @task_list = Current.account.task_lists.find(params[:task_list_id])
    @task_item = @task_list.task_items.find(params[:task_item_id])
    @comment = @task_item.comments.find(params[:id])
    require_comment_author! or return

    render "shared/comments/edit"
  end

  def update_comment
    @task_list = Current.account.task_lists.find(params[:task_list_id])
    @task_item = @task_list.task_items.find(params[:task_item_id])
    @comment = @task_item.comments.find(params[:id])
    require_comment_author! or return

    if @comment.update(comment_params)
      redirect_to task_list_task_item_path(@task_list, @task_item), notice: "Comment updated."
    else
      render "shared/comments/edit", status: :unprocessable_entity
    end
  end

  def destroy_comment
    @task_list = Current.account.task_lists.find(params[:task_list_id])
    @task_item = @task_list.task_items.find(params[:task_item_id])
    @comment = @task_item.comments.find(params[:id])
    require_comment_author! or return

    @comment.destroy!
    redirect_to task_list_task_item_path(@task_list, @task_item), notice: "Comment deleted."
  end

  private

  def require_task_list!
    raise ActiveRecord::RecordNotFound unless Current.task_list_id
  end

  def set_task_item
    @task_item = Current.task_items.find(params[:id])
    @task_list = Current.task_list
  end

  def task_item_params
    params.require(:task_item).permit(:name, :description, :completed, :assigned_user_id)
  end

  def require_comment_author!
    return true if @comment.user_id == Current.user.id

    redirect_to task_list_task_item_path(@task_list, @task_item), alert: "You can only modify your own comments."
    false
  end

  def comment_params
    params.require(:comment).permit(:body)
  end

  def task_items_url(...)
    task_list_task_items_url(Current.task_list_id, ...)
  end

  def task_item_url(...)
    task_list_task_item_url(Current.task_list_id, ...)
  end

  def next_location
    return my_tasks_url if params[:return_to] == "my_tasks"
    case params[:filter]
    when "completed" then task_items_url(filter: "completed")
    when "incomplete" then task_items_url(filter: "incomplete")
    when "show" then task_item_url(@task_item)
    else task_items_url
    end
  end
end
