# frozen_string_literal: true

class Web::Account::SwitchesController < Web::BaseController
  before_action :authenticate_user!

  def create
    account = Current.context.person.accounts.find(params[:account_id])

    session[:account_id] = account.id
    session.delete(:task_list_id)

    Current.authorize!(user_id: Current.user.id, account_id: account.id, task_list_id: nil)

    self.current_task_list_id = Current.task_list_id

    redirect_to home_path, notice: "Switched to #{account.name}."
  end
end
