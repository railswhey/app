# frozen_string_literal: true

class Web::User::Settings::TokensController < Web::BaseController
  before_action :authenticate_user!

  def edit
    render :edit
  end

  def update
    Current.user.user_token.refresh!

    cookies.encrypted[:user_token] = { value: Current.user.user_token.value, expires: 30.seconds.from_now }

    redirect_to(edit_user_settings_token_path, notice: "API token updated.")
  end
end
