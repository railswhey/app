# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # User registrations
  get  "users/new",  to: "user_registrations#new",    as: :new_user_registration
  post "users",      to: "user_registrations#create", as: :user_registrations

  # User account deletion
  delete "users", to: "user_account_deletions#destroy"

  # User sessions
  get    "users/session", to: "user_sessions#new",    as: :new_user_session
  post   "users/session", to: "user_sessions#create", as: :user_sessions
  delete "users/session", to: "user_sessions#destroy"

  # User passwords
  get  "users/password",     to: "user_passwords#new",    as: :new_user_password
  post "users/password",     to: "user_passwords#create", as: :user_passwords
  get  "users/:id/password", to: "user_passwords#edit",   as: :edit_user_password
  put  "users/:id/password", to: "user_passwords#update", as: :user_password

  # User tokens
  get "users/token", to: "user_tokens#edit",   as: :edit_user_token
  put "users/token", to: "user_tokens#update", as: :user_tokens

  # User profiles
  get "users/profile", to: "user_profiles#edit",   as: :edit_user_profile
  put "users/profile", to: "user_profiles#update", as: :user_profiles

  # Account management
  resources :account_switches, only: [ :create ]

  resource :account, only: [ :show, :update ] do
    get    "memberships",     to: "account_memberships#index",   as: :memberships
    delete "memberships/:id", to: "account_memberships#destroy", as: :membership

    get    "invitations",     to: "account_invitations#index",   as: :invitations
    get    "invitations/new", to: "account_invitations#new",     as: :new_invitation
    post   "invitations",     to: "account_invitations#create"
    delete "invitations/:id", to: "account_invitations#destroy", as: :invitation
  end

  # Invitation acceptance (public token-based)
  get   "invitations/:token", to: "account_invitations#show",   as: :show_invitation
  patch "invitations/:token", to: "account_invitations#update", as: :accept_invitation

  # Task lists + items
  resources :task_lists do
    # List comments
    post   "comments",          to: "task_list_comments#create",  as: :comments
    get    "comments/:id/edit", to: "task_list_comments#edit",    as: :edit_comment
    patch  "comments/:id",      to: "task_list_comments#update"
    put    "comments/:id",      to: "task_list_comments#update",  as: :comment
    delete "comments/:id",      to: "task_list_comments#destroy"

    resources :task_items do
      # Item comments
      post   "comments",          to: "task_item_comments#create",  as: :comments
      get    "comments/:id/edit", to: "task_item_comments#edit",    as: :edit_comment
      patch  "comments/:id",      to: "task_item_comments#update"
      put    "comments/:id",      to: "task_item_comments#update",  as: :comment
      delete "comments/:id",      to: "task_item_comments#destroy"
    end

    resources :complete_task_items, only: [ :update ]
    resources :incomplete_task_items, only: [ :update ]
    resources :task_item_moves, only: [ :create ]
  end

  # Task list transfers
  get  "task_lists/:task_list_id/transfer/new", to: "task_list_transfers#new",    as: :new_task_list_transfer
  post "task_lists/:task_list_id/transfer",     to: "task_list_transfers#create", as: :task_list_transfer_form

  # Transfer approval (public token-based)
  get   "transfers/:token", to: "task_list_transfers#show",   as: :show_task_list_transfer
  patch "transfers/:token", to: "task_list_transfers#update", as: :task_list_transfer

  # Notifications
  get "notifications",               to: "user_notifications#index",         as: :notifications
  post "notifications/reads", to: "user_notification_reads#create", as: :user_notification_reads
  put "notifications/:id",           to: "user_notifications#update",        as: :notification

  # My tasks, search, settings
  get "my_tasks", to: "task_item_assigned#index", as: :my_tasks
  get "search",   to: "search#show",                 as: :search
  get "settings", to: "user_settings#show",          as: :settings

  # API docs (public)
  get "api/docs(/:section)", to: "api_docs#show", as: :api_docs

  # Error pages
  match "/404", to: "errors#show", defaults: { status: 404 }, via: :all
  match "/422", to: "errors#show", defaults: { status: 422 }, via: :all
  match "/500", to: "errors#show", defaults: { status: 500 }, via: :all

  root "user_sessions#new"
end
