# frozen_string_literal: true

class Account::Invitations::AcceptancesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do |exception|
    raise exception unless request.format.json?

    render_json_with_failure(status: :not_found, message: "Not found.")
  end

  def show
    current_member!
    @invitation = Invitation.find_by!(token: params[:token])

    if @invitation.accepted?
      respond_to do |format|
        format.html { redirect_to new_user_session_path, notice: "This invitation has already been accepted." }
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

    render :show
  end

  def update
    current_member!
    @invitation = Invitation.find_by!(token: params[:token])

    if @invitation.accepted?
      respond_to do |format|
        format.html { redirect_to new_user_session_path, notice: "Already accepted." }
        format.json { render_json_with_failure(status: :unprocessable_entity, message: "Already accepted.") }
      end
      return
    end
    unless Current.user
      respond_to do |format|
        format.html do
          redirect_to new_user_session_path(return_to: account_invitations_acceptance_path(token: @invitation.token)),
                      notice: "Please sign in to accept the invitation."
        end
        format.json { render("errors/unauthorized", status: :unauthorized) }
      end
      return
    end
    if @invitation.accept!(Current.user)
      respond_to do |format|
        format.html { redirect_to home_path, notice: "You've joined #{@invitation.account.name}!" }
        format.json { render :show, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to account_invitations_acceptance_path(token: @invitation.token), alert: "Could not accept invitation." }
        format.json { render_json_with_failure(status: :unprocessable_entity, message: "Could not accept invitation.") }
      end
    end
  end
end
