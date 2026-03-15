# frozen_string_literal: true

Rails.application.routes.draw do
  scope module: :web, defaults: { format: "html" }, constraints: { format: "html" } do
    namespace :user do
      resources :registrations, only: [ :new, :create ]
      resource  :registration,  only: [ :destroy ]
      resource  :session,       only: [ :new, :create, :destroy ]
      resource  :password,      only: [ :new, :create, :edit, :update ]
      resource  :settings,      only: [ :show ]
      namespace :settings do
        resource :profile,  only: [ :edit, :update ]
        resource :password, only: [ :update ]
        resource :token,    only: [ :edit, :update ]
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
  end

  scope module: :web do
    # Outside the web scope because it also serves markdown (format: :md)
    get "api/docs(/:section)", to: "api_docs#show", as: :api_docs
  end

  constraints(format: "html") do
    # Outside the web scope because error requests may arrive without a format
    match "/404", to: "web/errors#show", defaults: { status: 404 }, via: :all
    match "/422", to: "web/errors#show", defaults: { status: 422 }, via: :all
    match "/500", to: "web/errors#show", defaults: { status: 500 }, via: :all
  end

  namespace :api, defaults: { format: "json" }, constraints: { format: "json" } do
    namespace :v1 do
      namespace :user do
        resource  :session,       only: [ :create ]
        resources :registrations, only: [ :create ]
        resource  :registration,  only: [ :destroy ]
        resource  :password,      only: [ :create, :update ]
        namespace :settings do
          resource :profile,  only: [ :update ]
          resource :password, only: [ :update ]
          resource :token,    only: [ :update ]
        end
      end

      namespace :account do
        resources :memberships, only: [ :index, :destroy ]
        resources :invitations, only: [ :index, :create, :destroy ]
        namespace :invitations do
          resource :acceptance, only: [ :show, :update ]
        end
        namespace :transfers do
          resource :response, only: [ :show, :update ]
        end
        resource :search, only: [ :show ]
      end

      namespace :task do
        namespace :item do
          resources :assignments, only: [ :index ]
        end
        resources :lists, except: [ :new, :edit ] do
          resources :items, except: [ :new, :edit ]
          namespace :item do
            resources :complete,   only: [ :update ]
            resources :incomplete, only: [ :update ]
            resources :moves,      only: [ :create ]
          end
          scope module: :list do
            resource :transfer, only: [ :create ]
          end
        end
      end
    end
  end

  constraints(format: "json") do
    # Outside the API namespace because it would prefix the path to /api/v1/404
    match "/404", to: "api/v1/errors#show", defaults: { status: 404 }, via: :all
    match "/422", to: "api/v1/errors#show", defaults: { status: 422 }, via: :all
    match "/500", to: "api/v1/errors#show", defaults: { status: 500 }, via: :all
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "web/user/sessions#new"
end
