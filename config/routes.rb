# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  namespace :user do
    resources :registrations, only: [ :new, :create ]
    delete "registrations", to: "account_deletions#destroy"
    resource :session, only: [ :new, :create, :destroy ]
    resources :passwords, only: [ :new, :create, :edit, :update ]
    resource :token, only: [ :edit, :update ]
    resource :profile, only: [ :edit, :update ]
    resources :notifications, only: [ :index, :update ]
    resources :notification_reads, only: [ :create ]
  end
  get "settings", to: "user/settings#show", as: :settings

  namespace :account do
    resources :switches, only: [ :create ]
    resource :management, only: [ :show, :update ], path: "", controller: "management"
    resources :memberships, only: [ :index, :destroy ]
    resources :invitations, only: [ :index, :new, :create, :destroy ]
  end

  # Invitation acceptance (public token-based)
  get   "invitations/:token", to: "account/invitations#show",   as: :show_invitation
  patch "invitations/:token", to: "account/invitations#update", as: :accept_invitation

  namespace :task do
    resources :lists do
      resources :items do
        resources :comments, controller: "item_comments", only: [ :create, :edit, :update, :destroy ]
      end
      resources :complete_items, only: [ :update ]
      resources :incomplete_items, only: [ :update ]
      resources :item_moves, only: [ :create ]
      resources :comments, controller: "list_comments", only: [ :create, :edit, :update, :destroy ]
    end
  end

  # Task list transfers (custom routes to avoid helper name conflicts)
  get  "task/lists/:list_id/transfer/new", to: "task/list_transfers#new",    as: :new_task_list_transfer
  post "task/lists/:list_id/transfer",     to: "task/list_transfers#create", as: :task_list_transfer_form

  # Transfer approval (public token-based)
  get   "transfers/:token", to: "task/list_transfers#show",   as: :show_task_list_transfer
  patch "transfers/:token", to: "task/list_transfers#update", as: :task_list_transfer

  get "my_tasks", to: "task/item_assigned#index", as: :my_tasks
  get "search",   to: "search#show",              as: :search

  # Password reset email links (URL format expected by mailers and tests)
  get "users/:id/password", to: "user/passwords#edit", as: :user_password_reset_link

  # API docs (public)
  get "api/docs(/:section)", to: "api_docs#show", as: :api_docs

  # Error pages
  match "/404", to: "errors#show", defaults: { status: 404 }, via: :all
  match "/422", to: "errors#show", defaults: { status: 422 }, via: :all
  match "/500", to: "errors#show", defaults: { status: 500 }, via: :all

  root "user/sessions#new"
end
