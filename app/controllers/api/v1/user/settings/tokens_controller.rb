# frozen_string_literal: true

class API::V1::User::Settings::TokensController < API::V1::BaseController
  before_action :authenticate_user!

  def update
    Current.user.token.refresh!

    @user = Current.user

    render :show, status: :ok
  end
end
