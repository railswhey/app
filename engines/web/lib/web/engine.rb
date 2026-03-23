# frozen_string_literal: true

module Web
  class Engine < ::Rails::Engine
    isolate_namespace Web

    initializer "web.mailer_url_helpers" do |app|
      app.config.to_prepare do
        ApplicationMailer.inject_url_helpers(Web::Engine.routes.url_helpers)
      end
    end

    initializer "web.assets" do |app|
      app.config.assets.paths << root.join("app/assets/stylesheets")
      app.config.assets.paths << root.join("app/assets/images")
      app.config.assets.paths << root.join("app/javascript")
    end
  end
end
