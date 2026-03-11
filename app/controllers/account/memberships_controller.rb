# frozen_string_literal: true

class Account::MembershipsController < ApplicationController
  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordNotFound do |exception|
    raise exception unless request.format.json?

    render_json_with_failure(status: :not_found, message: "Not found.")
  end

  def index
    @account = Current.account
    @memberships = @account.memberships.includes(:user).order(:role, :created_at)

    respond_to do |format|
      format.html
      format.json
    end
  end

  def destroy
    @account = Current.account
    @membership = @account.memberships.find(params[:id])

    unless @account.memberships.owner_or_admin.exists?(user: Current.user)
      respond_to do |format|
        format.html { redirect_to account_management_path, alert: "Only owners and admins can manage members." }
        format.json { render_json_with_failure(status: :forbidden, message: "Only owners and admins can manage members.") }
      end
      return
    end

    if @membership.owner?
      respond_to do |format|
        format.html { redirect_to account_management_path, alert: "Cannot remove the account owner." }
        format.json { render_json_with_failure(status: :unprocessable_entity, message: "Cannot remove the account owner.") }
      end
      return
    end
    if @membership.user == Current.user
      respond_to do |format|
        format.html { redirect_to account_management_path, alert: "Cannot remove yourself." }
        format.json { render_json_with_failure(status: :unprocessable_entity, message: "Cannot remove yourself.") }
      end
      return
    end
    @membership.destroy!
    respond_to do |format|
      format.html { redirect_to account_management_path, notice: "Member removed.", status: :see_other }
      format.json { head :no_content }
    end
  end
end
