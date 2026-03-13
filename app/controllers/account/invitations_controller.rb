# frozen_string_literal: true

class Account::InvitationsController < ApplicationController
  before_action :authenticate_user!, only: %i[index new create destroy]

  rescue_from ActiveRecord::RecordNotFound do |exception|
    raise exception unless request.format.json?

    render_json_with_failure(status: :not_found, message: "Invitation not found.")
  end

  def index
    guard_owner_or_admin! or return
    @account = Current.account
    @invitations = @account.invitations.order(created_at: :desc)

    respond_to do |format|
      format.html
      format.json
    end
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

      respond_to do |format|
        format.html { redirect_to account_management_path, notice: "Invitation sent to #{@invitation.email}." }
        format.json { render :show, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render_json_with_model_failure(@invitation) }
      end
    end
  end

  def destroy
    guard_owner_or_admin! or return
    @account = Current.account
    @invitation = @account.invitations.find(params[:id])
    @invitation.destroy!
    respond_to do |format|
      format.html { redirect_to account_management_path, notice: "Invitation revoked.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def guard_owner_or_admin!
    return true if Current.account.memberships.owner_or_admin.exists?(user: Current.user)

    respond_to do |format|
      format.html { redirect_to account_management_path, alert: "Only owners and admins can manage this." }
      format.json { render_json_with_failure(status: :forbidden, message: "Only owners and admins can manage this.") }
    end
    false
  end

  def invitation_params
    params.require(:invitation).permit(:email)
  end
end
