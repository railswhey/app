# frozen_string_literal: true

class Task::Item::CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @task_list = Current.account.task_lists.find(params[:list_id])
    @task_item = @task_list.task_items.find(params[:item_id])
    @comment = @task_item.comments.new(comment_params)
    @comment.user = Current.user

    if @comment.save
      redirect_to task_list_item_path(@task_list, @task_item), notice: "Comment added."
    else
      redirect_to task_list_item_path(@task_list, @task_item), alert: @comment.errors.full_messages.to_sentence
    end
  end

  def edit
    @task_list = Current.account.task_lists.find(params[:list_id])
    @task_item = @task_list.task_items.find(params[:item_id])
    @comment = @task_item.comments.find(params[:id])
    require_comment_author! or return

    render "task/shared/comments/edit"
  end

  def update
    @task_list = Current.account.task_lists.find(params[:list_id])
    @task_item = @task_list.task_items.find(params[:item_id])
    @comment = @task_item.comments.find(params[:id])
    require_comment_author! or return

    if @comment.update(comment_params)
      redirect_to task_list_item_path(@task_list, @task_item), notice: "Comment updated."
    else
      render "task/shared/comments/edit", status: :unprocessable_entity
    end
  end

  def destroy
    @task_list = Current.account.task_lists.find(params[:list_id])
    @task_item = @task_list.task_items.find(params[:item_id])
    @comment = @task_item.comments.find(params[:id])
    require_comment_author! or return

    @comment.destroy!
    redirect_to task_list_item_path(@task_list, @task_item), notice: "Comment deleted."
  end

  private

  def require_comment_author!
    return true if @comment.user_id == Current.user.id

    redirect_to task_list_item_path(@task_list, @task_item), alert: "You can only modify your own comments."
    false
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
