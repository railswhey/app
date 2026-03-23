# frozen_string_literal: true

class API::V1::Account::MembershipsController < API::V1::BaseController
  before_action :authenticate_user!
  before_action :set_account

  rescue_from ActiveRecord::RecordNotFound do
    render_json_with_failure(status: :not_found, message: "Not found.")
  end

  def index
    @memberships = @account.memberships.includes(:person).order(:role, :created_at)
  end

  def destroy
    @membership = @account.memberships.find(params[:id])

    unless owner_or_admin?
      return render_json_with_failure(status: :forbidden, message: "Only owners and admins can manage members.")
    end

    unless @membership.removable_by?(current.context.person)
      message = @membership.owner? ? "Cannot remove the account owner." : "Cannot remove yourself."

      return render_json_with_failure(status: :unprocessable_entity, message: message)
    end

    @membership.destroy!

    head :no_content
  end

  private

  def set_account
    @account = current.account
  end
end
