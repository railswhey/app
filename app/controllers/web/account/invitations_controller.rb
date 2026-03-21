# frozen_string_literal: true

class Web::Account::InvitationsController < Web::BaseController
  before_action :authenticate_user!, only: %i[index new create destroy]
  before_action :guard_owner_or_admin!
  before_action :set_account

  def index
    @invitations = @account.invitations.order(created_at: :desc)
  end

  def new
    @invitation = Account::Invitation.new

    render :new
  end

  def create
    case Account::DispatchInvitationProcess.perform_now(
      email: invitation_params[:email],
      account: @account,
      invited_by: Current.context.person
    )
    in [ :ok, invitation ]
      @invitation = invitation

      redirect_to account_management_path, notice: "Invitation sent to #{@invitation.email}."
    in [ :err, invitation ]
      @invitation = invitation

      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @invitation = @account.invitations.find(params[:id])

    @invitation.destroy!

    redirect_to account_management_path, notice: "Invitation revoked.", status: :see_other
  end

  private

  def guard_owner_or_admin!
    return true if owner_or_admin?

    redirect_to account_management_path, alert: "Only owners and admins can manage this."

    false
  end

  def set_account
    @account = Current.account
  end

  def invitation_params
    params.require(:invitation).permit(:email)
  end
end
