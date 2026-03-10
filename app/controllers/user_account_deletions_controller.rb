# frozen_string_literal: true

class UserAccountDeletionsController < ApplicationController
  before_action :authenticate_user!

  def destroy
    Current.user.destroy!

    respond_to do |format|
      format.html do
        sign_out

        redirect_to root_path, notice: "Your account has been deleted."
      end
      format.json { head :no_content }
    end
  end
end
