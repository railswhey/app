# frozen_string_literal: true

class AccountsController < ApplicationController
  before_action :authenticate_user!

  def switch
    account = Current.user.accounts.find(params[:id])
    session[:account_id] = account.id
    session.delete(:task_list_id)

    # Reload Current with the new account so home_path resolves the new inbox.
    Current.member!(user_id: Current.user.id, account_id: account.id, task_list_id: nil)
    self.current_task_list_id = Current.task_list_id

    redirect_to home_path, notice: "Switched to #{account.name}."
  end

  def show
    @account     = Current.account
    @memberships = @account.memberships.includes(:user).order(:role, :created_at)
    @invitations = @account.invitations.order(created_at: :desc)
    @incoming_transfers = @account.incoming_transfers.pending.includes(:task_list, :from_account, :transferred_by)
  end

  def update
    @account = Current.account
    if @account.update(account_params)
      redirect_to account_path, notice: "Account updated."
    else
      @memberships = @account.memberships.includes(:user).order(:role, :created_at)
      @invitations = @account.invitations.order(created_at: :desc)
      @incoming_transfers = @account.incoming_transfers.pending.includes(:task_list, :from_account, :transferred_by)
      render :show, status: :unprocessable_entity
    end
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    raise exception unless request.format.json?

    render_json_with_failure(status: :not_found, message: "Not found.")
  end

  private

  def account_params
    params.require(:account).permit(:name)
  end
end
