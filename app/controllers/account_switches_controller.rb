# frozen_string_literal: true

class AccountSwitchesController < ApplicationController
  before_action :authenticate_user!

  def create
    account = Current.user.accounts.find(params[:account_id])
    session[:account_id] = account.id
    session.delete(:task_list_id)

    # Reload Current with the new account so home_path resolves the new inbox.
    Current.member!(user_id: Current.user.id, account_id: account.id, task_list_id: nil)
    self.current_task_list_id = Current.task_list_id

    redirect_to home_path, notice: "Switched to #{account.name}."
  end
end
