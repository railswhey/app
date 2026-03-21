# frozen_string_literal: true

class Web::Account::Invitations::AcceptancesController < Web::BaseController
  before_action :current_member!
  before_action :set_invitation

  def show
    if @invitation.accepted?
      return redirect_to new_user_session_path, notice: "This invitation has already been accepted."
    end

    if Current.user && !@invitation.acceptable_by?(Current.user)
      return redirect_to home_path, notice: "You are already a member of this account."
    end

    render :show
  end

  def update
    if @invitation.accepted?
      return redirect_to new_user_session_path, notice: "Already accepted."
    end

    unless Current.user
      path = new_user_session_path(return_to: account_invitations_acceptance_path(token: @invitation.token))

      return redirect_to path, notice: "Please sign in to accept the invitation."
    end

    case Account::AcceptInvitationProcess.perform_now(invitation: @invitation, user: Current.user)
    in [ :ok, _ ]
      redirect_to home_path, notice: "You've joined #{@invitation.account.name}!"
    in [ :err, _ ]
      redirect_to account_invitations_acceptance_path(token: @invitation.token),
                  alert: "Could not accept invitation."
    end
  end

  private

  def set_invitation
    @invitation = Account::Invitation.find_by!(token: params[:token])
  end
end
