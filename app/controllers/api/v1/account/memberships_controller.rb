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

    unless @account.memberships.owner_or_admin.exists?(user: Current.user)
      render_json_with_failure(status: :forbidden, message: "Only owners and admins can manage members.")
      return
    end

    if @membership.owner?
      render_json_with_failure(status: :unprocessable_entity, message: "Cannot remove the account owner.")
      return
    end

    if @membership.user == Current.user
      render_json_with_failure(status: :unprocessable_entity, message: "Cannot remove yourself.")
      return
    end

    @membership.destroy!
    head :no_content
  end
end
