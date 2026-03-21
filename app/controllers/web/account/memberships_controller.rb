# frozen_string_literal: true

class Web::Account::MembershipsController < Web::BaseController
  before_action :authenticate_user!
  before_action :set_account

  def index
    @memberships = @account.memberships.includes(:person).order(:role, :created_at)
  end

  def destroy
    @membership = @account.memberships.find(params[:id])

    unless owner_or_admin?
      return redirect_to account_management_path, alert: "Only owners and admins can manage members."
    end

    unless @membership.removable_by?(Current.context.person)
      message = @membership.owner? ? "Cannot remove the account owner." : "Cannot remove yourself."

      return redirect_to account_management_path, alert: message
    end

    @membership.destroy!

    redirect_to account_management_path, notice: "Member removed.", status: :see_other
  end

  private

  def set_account
    @account = Current.account
  end
end
