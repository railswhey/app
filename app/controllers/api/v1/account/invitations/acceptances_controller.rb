# frozen_string_literal: true

class API::V1::Account::Invitations::AcceptancesController < API::V1::BaseController
  rescue_from ActiveRecord::RecordNotFound do
    render_json_with_failure(status: :not_found, message: "Not found.")
  end

  def show
    current_member!
    @invitation = Invitation.find_by!(token: params[:token])

    if @invitation.accepted?
      render_json_with_failure(status: :unprocessable_entity, message: "This invitation has already been accepted.")
      return
    end

    if Current.user && !@invitation.acceptable_by?(Current.user)
      render_json_with_failure(status: :unprocessable_entity, message: "You are already a member of this account.")
      return
    end

    render :show
  end

  def update
    current_member!
    @invitation = Invitation.find_by!(token: params[:token])

    if @invitation.accepted?
      render_json_with_failure(status: :unprocessable_entity, message: "Already accepted.")
      return
    end

    unless Current.user
      render("errors/unauthorized", status: :unauthorized)
      return
    end

    if @invitation.accept!(Current.user)
      render :show, status: :ok
    else
      render_json_with_failure(status: :unprocessable_entity, message: "Could not accept invitation.")
    end
  end
end
