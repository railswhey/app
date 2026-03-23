# frozen_string_literal: true

Rails.application.routes.draw do
  # BOOT_* (Gemfile) controls loading. MOUNT_* controls route exposure.
  # Engine must be loaded (defined?) AND not explicitly unmounted.
  mount Web::Engine, at: "/" if defined?(Web::Engine) && ENV["MOUNT_WEB"] != "false"
  mount API::Engine, at: "/api" if defined?(API::Engine) && ENV["MOUNT_API"] != "false"

  # Error routes stay in the host because config.exceptions_app = routes
  # uses the HOST app's route set. Engine controllers are autoloadable
  # from the host (the engine's app/controllers/ is in the autoload paths).
  constraints(format: "html") do
    match "/404", to: "web/errors#show", defaults: { status: 404 }, via: :all
    match "/422", to: "web/errors#show", defaults: { status: 422 }, via: :all
    match "/500", to: "web/errors#show", defaults: { status: 500 }, via: :all
  end

  constraints(format: "json") do
    match "/404", to: "api/v1/errors#show", defaults: { status: 404 }, via: :all
    match "/422", to: "api/v1/errors#show", defaults: { status: 422 }, via: :all
    match "/500", to: "api/v1/errors#show", defaults: { status: 500 }, via: :all
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
