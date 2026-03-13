# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :user do
    resources :registrations, only: [ :new, :create ]
    resource  :registration,  only: [ :destroy ]
    resource  :session,       only: [ :new, :create, :destroy ]
    resource  :password,      only: [ :new, :create, :edit, :update ]
    resource  :settings,      only: [ :show ]
    namespace :settings do
      resource :profile, only: [ :edit, :update ]
      resource :token,   only: [ :edit, :update ]
    end
    namespace :notification do
      resources :inbox, only: [ :index, :update ]
      resources :reads, only: [ :create ]
    end
  end

  namespace :account do
    resources :switches,    only: [ :create ]
    resource  :management,  only: [ :show, :update ]
    resources :memberships, only: [ :index, :destroy ]
    resources :invitations, only: [ :index, :new, :create, :destroy ]
    namespace :invitations do
      resource :acceptance, only: [ :show, :update ]
    end
    namespace :transfers do
      resource :response, only: [ :show, :update ]
    end
    resource  :search, only: [ :show ]
  end

  namespace :task do
    namespace :item do
      resources :assignments, only: [ :index ]
    end
    resources :lists do
      resources :items do
        scope module: :item do
          resources :comments, only: [ :create, :edit, :update, :destroy ]
        end
      end
      namespace :item do
        resources :complete,   only: [ :update ]
        resources :incomplete, only: [ :update ]
        resources :moves,      only: [ :create ]
      end
      scope module: :list do
        resources :comments, only: [ :create, :edit, :update, :destroy ]
        resource  :transfer,  only: [ :new, :create ]
      end
    end
  end

  # API docs (public)
  get "api/docs(/:section)", to: "api_docs#show", as: :api_docs

  # Error pages
  match "/404", to: "errors#show", defaults: { status: 404 }, via: :all
  match "/422", to: "errors#show", defaults: { status: 422 }, via: :all
  match "/500", to: "errors#show", defaults: { status: 500 }, via: :all

  # Health check and PWA endpoints
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "user/sessions#new"
end
