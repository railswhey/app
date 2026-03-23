# frozen_string_literal: true

class Web::Account::ManagementsController < Web::BaseController
  before_action :authenticate_user!
  before_action :set_management_data

  def show
  end

  def update
    if @account.update(account_params)
      redirect_to account_management_path, notice: "Account updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_management_data
    @account            = current.account
    @memberships        = @account.memberships.includes(:person).order(:role, :created_at)
    @invitations        = @account.invitations.order(created_at: :desc)
    @incoming_transfers = current.workspace.incoming_transfers.pending.includes(:list, :from_workspace, :initiated_by)
    @transfer_accounts  = ::Account.where(uuid: @incoming_transfers.map { it.from_workspace.uuid }).index_by(&:uuid)
  end

  def account_params
    params.require(:account).permit(:name)
  end
end
