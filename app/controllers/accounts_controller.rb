# frozen_string_literal: true

class AccountsController < ApplicationController
  before_action :authenticate_user!, except: %i[show_invitation accept_invitation]

  def switch
    account = Current.user.accounts.find(params[:id])
    session[:account_id] = account.id
    session.delete(:task_list_id)

    # Reload Current with the new account so home_path resolves the new inbox.
    Current.member!(user_id: Current.user.id, account_id: account.id, task_list_id: nil)
    self.current_task_list_id = Current.task_list_id

    redirect_to home_path, notice: "Switched to #{account.name}."
  end

  def show
    @account     = Current.account
    @memberships = @account.memberships.includes(:user).order(:role, :created_at)
    @invitations = @account.invitations.order(created_at: :desc)
    @incoming_transfers = @account.incoming_transfers.pending.includes(:task_list, :from_account, :transferred_by)
  end

  def update
    @account = Current.account
    if @account.update(account_params)
      redirect_to account_path, notice: "Account updated."
    else
      @memberships = @account.memberships.includes(:user).order(:role, :created_at)
      @invitations = @account.invitations.order(created_at: :desc)
      @incoming_transfers = @account.incoming_transfers.pending.includes(:task_list, :from_account, :transferred_by)
      render :show, status: :unprocessable_entity
    end
  end

  def memberships
    @account = Current.account
    @memberships = @account.memberships.includes(:user).order(:role, :created_at)

    respond_to do |format|
      format.html { render :memberships }
      format.json { render :memberships }
    end
  end

  def destroy_membership
    @account = Current.account
    @membership = @account.memberships.find(params[:id])

    unless @account.memberships.owner_or_admin.exists?(user: Current.user)
      respond_to do |format|
        format.html { redirect_to account_path, alert: "Only owners and admins can manage members." }
        format.json { render_json_with_failure(status: :forbidden, message: "Only owners and admins can manage members.") }
      end
      return
    end

    if @membership.owner?
      respond_to do |format|
        format.html { redirect_to account_path, alert: "Cannot remove the account owner." }
        format.json { render_json_with_failure(status: :unprocessable_entity, message: "Cannot remove the account owner.") }
      end
      return
    end
    if @membership.user == Current.user
      respond_to do |format|
        format.html { redirect_to account_path, alert: "Cannot remove yourself." }
        format.json { render_json_with_failure(status: :unprocessable_entity, message: "Cannot remove yourself.") }
      end
      return
    end
    @membership.destroy!
    respond_to do |format|
      format.html { redirect_to account_path, notice: "Member removed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def invitations
    guard_owner_or_admin! or return
    @account = Current.account
    @invitations = @account.invitations.order(created_at: :desc)

    respond_to do |format|
      format.html { render :invitations }
      format.json { render :invitations }
    end
  end

  def new_invitation
    guard_owner_or_admin! or return
    @account = Current.account
    @invitation = Invitation.new

    render :new_invitation
  end

  def create_invitation
    guard_owner_or_admin! or return
    @account = Current.account
    @invitation = @account.invitations.new(invitation_params.merge(invited_by: Current.user))
    if @invitation.save
      InvitationMailer.invite(@invitation).deliver_later

      if (invitee = User.find_by(email: @invitation.email))
        @invitation.notify_invitee!(invitee)
      end

      respond_to do |format|
        format.html { redirect_to account_path, notice: "Invitation sent to #{@invitation.email}." }
        format.json { render :show_invitation, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new_invitation, status: :unprocessable_entity }
        format.json { render_json_with_model_failure(@invitation) }
      end
    end
  end

  def show_invitation
    current_member!
    @invitation = Invitation.find_by!(token: params[:token])

    if @invitation.accepted?
      respond_to do |format|
        format.html { redirect_to new_session_users_path, notice: "This invitation has already been accepted." }
        format.json { render_json_with_failure(status: :unprocessable_entity, message: "This invitation has already been accepted.") }
      end
      return
    end
    if Current.user && @invitation.account.memberships.exists?(user: Current.user)
      respond_to do |format|
        format.html { redirect_to home_path, notice: "You are already a member of this account." }
        format.json { render_json_with_failure(status: :unprocessable_entity, message: "You are already a member of this account.") }
      end
      return
    end

    render :show_invitation
  end

  def accept_invitation
    current_member!
    @invitation = Invitation.find_by!(token: params[:token])

    if @invitation.accepted?
      respond_to do |format|
        format.html { redirect_to new_session_users_path, notice: "Already accepted." }
        format.json { render_json_with_failure(status: :unprocessable_entity, message: "Already accepted.") }
      end
      return
    end
    unless Current.user
      respond_to do |format|
        format.html do
          redirect_to new_session_users_path(return_to: show_invitation_path(@invitation.token)),
                      notice: "Please sign in to accept the invitation."
        end
        format.json { render("errors/unauthorized", status: :unauthorized) }
      end
      return
    end
    if @invitation.accept!(Current.user)
      respond_to do |format|
        format.html { redirect_to home_path, notice: "You've joined #{@invitation.account.name}!" }
        format.json { render :show_invitation, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to show_invitation_path(@invitation.token), alert: "Could not accept invitation." }
        format.json { render_json_with_failure(status: :unprocessable_entity, message: "Could not accept invitation.") }
      end
    end
  end

  def destroy_invitation
    guard_owner_or_admin! or return
    @account = Current.account
    @invitation = @account.invitations.find(params[:id])
    @invitation.destroy!
    respond_to do |format|
      format.html { redirect_to account_path, notice: "Invitation revoked.", status: :see_other }
      format.json { head :no_content }
    end
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    raise exception unless request.format.json?

    render_json_with_failure(status: :not_found, message: "Not found.")
  end

  private

  def guard_owner_or_admin!
    return true if Current.account.memberships.owner_or_admin.exists?(user: Current.user)

    respond_to do |format|
      format.html { redirect_to account_path, alert: "Only owners and admins can manage this." }
      format.json { render_json_with_failure(status: :forbidden, message: "Only owners and admins can manage this.") }
    end
    false
  end

  def invitation_params
    params.require(:invitation).permit(:email)
  end

  def account_params
    params.require(:account).permit(:name)
  end
end
