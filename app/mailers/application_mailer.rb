# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"

  # Extension point: engine initializers inject route helpers here.
  # The kernel defines the contract; the engine fulfills it.
  # See: engines/web/lib/web/engine.rb
  def self.inject_url_helpers(mod)
    unless include?(mod)
      prepend mod
      helper mod
    end
  end
end
