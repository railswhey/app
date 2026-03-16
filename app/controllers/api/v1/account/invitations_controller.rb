# frozen_string_literal: true

class API::V1::Account::InvitationsController < API::V1::BaseController
  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordNotFound do
    render_json_with_failure(status: :not_found, message: "Invitation not found.")
  end

  def index
    guard_owner_or_admin! or return
    @account = Current.account
    @invitations = @account.invitations.order(created_at: :desc)
  end

  def create
    guard_owner_or_admin! or return
    @account = Current.account
    @invitation = @account.invitations.new(invitation_params.merge(invited_by: Current.user))
    if @invitation.save
      render :show, status: :created
    else
      render_json_with_model_failure(@invitation)
    end
  end

  def destroy
    guard_owner_or_admin! or return
    @account = Current.account
    @invitation = @account.invitations.find(params[:id])
    @invitation.destroy!
    head :no_content
  end

  private

  def guard_owner_or_admin!
    return true if owner_or_admin?

    render_json_with_failure(status: :forbidden, message: "Only owners and admins can manage this.")
    false
  end

  def invitation_params
    params.require(:invitation).permit(:email)
  end
end
