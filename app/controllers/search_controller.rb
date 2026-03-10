# frozen_string_literal: true

class SearchController < ApplicationController
  before_action :authenticate_user!

  def show
    @query = params[:q].to_s.strip

    if @query.length >= 2
      @task_items = TaskItem
        .joins(:task_list)
        .where(task_lists: { account_id: Current.account_id })
        .search(@query)
        .includes(:task_list)
        .order(created_at: :desc)
        .limit(20)

      @task_lists = Current.account.task_lists
        .where("name LIKE ? OR description LIKE ?", "%#{@query}%", "%#{@query}%")
        .limit(10)

      @comments = Comment
        .for_account(Current.account_id)
        .search(@query)
        .includes(:user, :commentable)
        .order(created_at: :desc)
        .limit(10)
    else
      @task_items = TaskItem.none
      @task_lists = TaskList.none
      @comments = Comment.none
    end

    respond_to do |format|
      format.html
      format.json { render :show }
    end
  end
end
