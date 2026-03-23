# frozen_string_literal: true

class Web::Task::Item::CommentsController < Web::BaseController
  before_action :authenticate_user!
  before_action :set_commentable!

  with_options only: %i[edit update destroy] do
    before_action :set_comment
    before_action :require_comment_author!
  end

  def create
    @comment = @task_item.comments.new(comment_params)
    @comment.member = current.workspace.member

    if @comment.save
      redirect_to task_list_item_path(@task_list, @task_item), notice: "Comment added."
    else
      redirect_to task_list_item_path(@task_list, @task_item), alert: @comment.errors.full_messages.to_sentence
    end
  end

  def edit
    render "task/shared/comments/edit"
  end

  def update
    if @comment.update(comment_params)
      redirect_to task_list_item_path(@task_list, @task_item), notice: "Comment updated."
    else
      render "task/shared/comments/edit", status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy!

    redirect_to task_list_item_path(@task_list, @task_item), notice: "Comment deleted."
  end

  private

  def set_commentable!
    @task_list = current.task_lists.find(params[:list_id])
    @task_item = @task_list.tasks.find(params[:item_id])
  end

  def set_comment
    @comment = @task_item.comments.find(params[:id])
  end

  def require_comment_author!
    return true if @comment.authored_by?(current.workspace.member)

    redirect_to task_list_item_path(@task_list, @task_item), alert: "You can only modify your own comments."

    false
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
