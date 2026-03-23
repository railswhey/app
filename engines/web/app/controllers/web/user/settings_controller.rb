# frozen_string_literal: true

class Web::User::SettingsController < Web::BaseController
  before_action :authenticate_user!

  def show
  end
end
