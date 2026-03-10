# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Auth + profile
  resource :users, only: [ :destroy ]
  resources :users, only: [ :new, :create ] do
    collection do
      match :session,  action: :new_session,     via: [ :get ],    as: :new_session
      match :session,  action: :create_session,  via: [ :post ]
      match :session,  action: :destroy_session, via: [ :delete ]
      match :password, action: :new_password,    via: [ :get ],    as: :new_password
      match :password, action: :create_password, via: [ :post ]
      match :profile,  action: :edit_profile,    via: [ :get ],    as: :edit_profile
      match :profile,  action: :update_profile,  via: [ :put ]
      match :token,    action: :edit_token,      via: [ :get ],    as: :edit_token
      match :token,    action: :update_token,    via: [ :put ]
    end

    member do
      match :password, action: :edit_password,   via: [ :get ],    as: :edit_password
      match :password, action: :update_password, via: [ :put ]
    end
  end

  # Account management
  post "accounts/:id/switch", to: "accounts#switch", as: :switch_account

  resource :account, only: [ :show, :update ] do
    get    "memberships",     action: :memberships,        as: :memberships
    delete "memberships/:id", action: :destroy_membership, as: :membership

    get    "invitations",       action: :invitations,         as: :invitations
    get    "invitations/new",   action: :new_invitation,      as: :new_invitation
    post   "invitations",       action: :create_invitation
    delete "invitations/:id",   action: :destroy_invitation,  as: :invitation
  end

  # Invitation acceptance (public token-based)
  get   "invitations/:token", to: "accounts#show_invitation",   as: :show_invitation
  patch "invitations/:token", to: "accounts#accept_invitation", as: :accept_invitation

  # Task lists + items + comments
  resources :task_lists do
    # List comments (handled by task_lists controller)
    post   "comments",          action: :create_comment,  as: :comments
    get    "comments/:id/edit", action: :edit_comment,    as: :edit_comment
    patch  "comments/:id",      action: :update_comment
    put    "comments/:id",      action: :update_comment,  as: :comment
    delete "comments/:id",      action: :destroy_comment

    resources :task_items do
      member do
        put :complete
        put :incomplete
        put :move
      end
      # Item comments (handled by task_items controller)
      post   "comments",          action: :create_comment,  as: :comments
      get    "comments/:id/edit", action: :edit_comment,    as: :edit_comment
      patch  "comments/:id",      action: :update_comment
      put    "comments/:id",      action: :update_comment,  as: :comment
      delete "comments/:id",      action: :destroy_comment
    end
  end

  # Task list transfer - new/create (nested under task_list)
  get  "task_lists/:task_list_id/transfer/new", to: "task_lists#new_transfer",    as: :new_task_list_transfer
  post "task_lists/:task_list_id/transfer",     to: "task_lists#create_transfer",  as: :task_list_transfer_form

  # Transfer approval (public token-based)
  get   "transfers/:token", to: "task_lists#show_transfer",   as: :show_task_list_transfer
  patch "transfers/:token", to: "task_lists#update_transfer",  as: :task_list_transfer

  # Notifications
  get "notifications",               to: "users#notifications",                as: :notifications
  put "notifications/mark_all_read", to: "users#mark_all_notifications_read",  as: :mark_all_read_notifications
  put "notifications/:id",           to: "users#update_notification",          as: :notification

  # My tasks + search + settings
  get "my_tasks",  to: "task_items#my_tasks",   as: :my_tasks
  get "search",    to: "search#show",      as: :search
  get "settings",  to: "users#settings",    as: :settings

  # API docs (public)
  get "api/docs/raw",        to: "api_docs#raw",  as: :api_docs_raw
  get "api/docs(/:section)", to: "api_docs#show", as: :api_docs

  # Error pages
  match "/404", to: "errors#not_found",            via: :all
  match "/422", to: "errors#unprocessable_entity",  via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  root "users#new_session"
end
