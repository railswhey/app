# frozen_string_literal: true

class Web::Account::SwitchesController < Web::BaseController
  before_action :authenticate_user!

  def create
    account = current.context.person.accounts.find(params[:account_id])

    session[:account_id] = account.id
    session.delete(:task_list_id)

    current.authorize!(user_id: current.user.id, account_id: account.id, task_list_id: nil)

    self.current_task_list_id = current.task_list_id

    redirect_to home_path, notice: "Switched to #{account.name}."
  end
end
