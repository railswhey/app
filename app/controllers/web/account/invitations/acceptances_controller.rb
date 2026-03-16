# frozen_string_literal: true

class Web::Account::Invitations::AcceptancesController < Web::BaseController
  def show
    current_member!
    @invitation = Account::Invitation.find_by!(token: params[:token])

    if @invitation.accepted?
      redirect_to new_user_session_path, notice: "This invitation has already been accepted."
      return
    end
    if Current.user && !@invitation.acceptable_by?(Current.user)
      redirect_to home_path, notice: "You are already a member of this account."
      return
    end

    render :show
  end

  def update
    current_member!
    @invitation = Account::Invitation.find_by!(token: params[:token])

    if @invitation.accepted?
      redirect_to new_user_session_path, notice: "Already accepted."
      return
    end
    unless Current.user
      redirect_to new_user_session_path(return_to: account_invitations_acceptance_path(token: @invitation.token)),
                  notice: "Please sign in to accept the invitation."
      return
    end
    if @invitation.accept!(Current.user)
      redirect_to home_path, notice: "You've joined #{@invitation.account.name}!"
    else
      redirect_to account_invitations_acceptance_path(token: @invitation.token), alert: "Could not accept invitation."
    end
  end
end
