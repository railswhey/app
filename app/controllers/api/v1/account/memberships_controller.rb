# frozen_string_literal: true

class API::V1::Account::MembershipsController < API::V1::BaseController
  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordNotFound do
    render_json_with_failure(status: :not_found, message: "Not found.")
  end

  def index
    @account = Current.account
    @memberships = @account.memberships.includes(:user).order(:role, :created_at)
  end

  def destroy
    @account = Current.account
    @membership = @account.memberships.find(params[:id])

    unless owner_or_admin?
      render_json_with_failure(status: :forbidden, message: "Only owners and admins can manage members.")
      return
    end

    unless @membership.removable_by?(Current.user)
      message = @membership.owner? ? "Cannot remove the account owner." : "Cannot remove yourself."
      render_json_with_failure(status: :unprocessable_entity, message: message)
      return
    end

    @membership.destroy!
    head :no_content
  end
end
