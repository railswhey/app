# frozen_string_literal: true

class Web::Account::MembershipsController < Web::BaseController
  before_action :authenticate_user!

  def index
    @account = Current.account
    @memberships = @account.memberships.includes(:user).order(:role, :created_at)
  end

  def destroy
    @account = Current.account
    @membership = @account.memberships.find(params[:id])

    unless owner_or_admin?
      redirect_to account_management_path, alert: "Only owners and admins can manage members."
      return
    end

    if @membership.owner?
      redirect_to account_management_path, alert: "Cannot remove the account owner."
      return
    end
    if @membership.user == Current.user
      redirect_to account_management_path, alert: "Cannot remove yourself."
      return
    end
    @membership.destroy!
    redirect_to account_management_path, notice: "Member removed.", status: :see_other
  end
end
