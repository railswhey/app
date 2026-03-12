# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  namespace :user do
    resources :registrations, only: [ :new, :create ]
    resource :registration, only: [ :destroy ]
    resource :session, only: [ :new, :create, :destroy ]
    resource :password, only: [ :new, :create, :edit, :update ]
    namespace :settings do
      resource :profile, only: [ :edit, :update ]
      resource :token, only: [ :edit, :update ]
    end
    namespace :notification do
      resources :inbox, only: [ :index, :update ]
      resources :reads, only: [ :create ]
    end
  end
  get "settings", to: "user/settings#show", as: :settings

  namespace :account do
    resources :switches, only: [ :create ]
    resource :management, only: [ :show, :update ], path: "", controller: "management"
    resources :memberships, only: [ :index, :destroy ]
    resources :invitations, only: [ :index, :new, :create, :destroy ]
  end

  resources :invitations, only: [ :show, :update ],
            controller: "account/invitations", param: :token

  namespace :task do
    resources :lists do
      resources :items do
        resources :comments, only: [ :create, :edit, :update, :destroy ], module: "item"
      end
      namespace :item do
        resources :complete, only: [ :update ]
        resources :incomplete, only: [ :update ]
        resources :moves, only: [ :create ]
      end
      resources :comments, only: [ :create, :edit, :update, :destroy ], module: "list"
      resource :transfer, only: [ :new, :create ], module: "list"
    end
  end

  get "my_tasks", to: "task/item/assigned#index", as: :my_tasks
  get "search",   to: "search#show",              as: :search

  resources :transfers, only: [ :show, :update ],
            controller: "task/list/transfers", param: :token

  # API docs (public)
  get "api/docs(/:section)", to: "api_docs#show", as: :api_docs

  # Error pages
  match "/404", to: "errors#show", defaults: { status: 404 }, via: :all
  match "/422", to: "errors#show", defaults: { status: 422 }, via: :all
  match "/500", to: "errors#show", defaults: { status: 500 }, via: :all

  root "user/sessions#new"
end
