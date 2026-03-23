# frozen_string_literal: true

class API::V1::Account::Invitations::AcceptancesController < API::V1::BaseController
  before_action :current_member!
  before_action :set_invitation, only: %i[show update]

  rescue_from ActiveRecord::RecordNotFound do
    render_json_with_failure(status: :not_found, message: "Not found.")
  end

  def show
    if @invitation.accepted?
      render_json_with_failure(status: :unprocessable_entity, message: "This invitation has already been accepted.")
      return
    end

    if current.user && !@invitation.acceptable_by?(current.user)
      render_json_with_failure(status: :unprocessable_entity, message: "You are already a member of this account.")
      return
    end

    render :show
  end

  def update
    if @invitation.accepted?
      render_json_with_failure(status: :unprocessable_entity, message: "Already accepted.")
      return
    end

    return render("errors/unauthorized", status: :unauthorized) unless current.user

    case ::Account::AcceptInvitationProcess.perform_now(invitation: @invitation, user: current.user)
    in [ :ok, _ ]
      render :show, status: :ok
    in [ :err, _ ]
      render_json_with_failure(status: :unprocessable_entity, message: "Could not accept invitation.")
    end
  end

  private

  def set_invitation
    @invitation = ::Account::Invitation.find_by!(token: params[:token])
  end
end
