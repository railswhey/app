# frozen_string_literal: true

module UsersSettingsConcern
  extend ActiveSupport::Concern

  def settings
    render :settings
  end
end
