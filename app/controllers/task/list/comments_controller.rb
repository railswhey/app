# frozen_string_literal: true

class Task::List::CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @task_list = Current.task_lists.find(params[:list_id])
    @comment = @task_list.comments.new(comment_params)
    @comment.user = Current.user

    if @comment.save
      redirect_to task_list_path(@task_list), notice: "Comment added."
    else
      redirect_to task_list_path(@task_list), alert: @comment.errors.full_messages.to_sentence
    end
  end

  def edit
    @task_list = Current.task_lists.find(params[:list_id])
    @comment = @task_list.comments.find(params[:id])
    require_comment_author! or return

    render "shared/comments/edit"
  end

  def update
    @task_list = Current.task_lists.find(params[:list_id])
    @comment = @task_list.comments.find(params[:id])
    require_comment_author! or return

    if @comment.update(comment_params)
      redirect_to task_list_path(@task_list), notice: "Comment updated."
    else
      render "shared/comments/edit", status: :unprocessable_entity
    end
  end

  def destroy
    @task_list = Current.task_lists.find(params[:list_id])
    @comment = @task_list.comments.find(params[:id])
    require_comment_author! or return

    @comment.destroy!
    redirect_to task_list_path(@task_list), notice: "Comment deleted."
  end

  private

  def require_comment_author!
    return true if @comment.user_id == Current.user.id

    redirect_to task_list_path(@task_list), alert: "You can only modify your own comments."
    false
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
