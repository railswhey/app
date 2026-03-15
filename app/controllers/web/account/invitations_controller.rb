# frozen_string_literal: true

class Web::Account::InvitationsController < Web::BaseController
  before_action :authenticate_user!, only: %i[index new create destroy]

  def index
    guard_owner_or_admin! or return
    @account = Current.account
    @invitations = @account.invitations.order(created_at: :desc)
  end

  def new
    guard_owner_or_admin! or return
    @account = Current.account
    @invitation = Invitation.new

    render :new
  end

  def create
    guard_owner_or_admin! or return
    @account = Current.account
    @invitation = @account.invitations.new(invitation_params.merge(invited_by: Current.user))
    if @invitation.save
      Account::InvitationMailer.invite(@invitation).deliver_later

      if (invitee = User.find_by(email: @invitation.email))
        @invitation.notify_invitee!(invitee)
      end

      redirect_to account_management_path, notice: "Invitation sent to #{@invitation.email}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    guard_owner_or_admin! or return
    @account = Current.account
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

  def invitation_params
    params.require(:invitation).permit(:email)
  end
end
