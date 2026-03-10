# frozen_string_literal: true

module UsersTokensConcern
  extend ActiveSupport::Concern

  def edit_token
  end

  def update_token
    Current.user.user_token.refresh!

    respond_to do |format|
      format.html do
        cookies.encrypted[:user_token] = { value: Current.user.user_token.value, expires: 30.seconds.from_now }

        redirect_to(edit_token_users_path, notice: "API token updated.")
      end
      format.json do
        @user = Current.user

        render "users/user_token", status: :ok
      end
    end
  end
end
