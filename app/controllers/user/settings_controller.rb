# frozen_string_literal: true

class User::SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
  end
end
