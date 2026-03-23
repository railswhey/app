# frozen_string_literal: true

class API::V1::Account::InvitationsController < API::V1::BaseController
  before_action :authenticate_user!
  before_action :guard_owner_or_admin!
  before_action :set_account

  rescue_from ActiveRecord::RecordNotFound do
    render_json_with_failure(status: :not_found, message: "Invitation not found.")
  end

  def index
    @invitations = @account.invitations.order(created_at: :desc)
  end

  def create
    case ::Account::DispatchInvitationProcess.perform_now(
      email: invitation_params[:email],
      account: @account,
      invited_by: current.context.person
    )
    in [ :ok, invitation ]
      @invitation = invitation

      render :show, status: :created
    in [ :err, invitation ]
      render_json_with_model_failure(invitation)
    end
  end

  def destroy
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

  def set_account
    @account = current.account
  end

  def invitation_params
    params.require(:invitation).permit(:email)
  end
end
