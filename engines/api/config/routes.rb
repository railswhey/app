# frozen_string_literal: true

API::Engine.routes.draw do
  namespace :v1, defaults: { format: "json" }, constraints: { format: "json" } do
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

  # Error routes stay in the HOST app's config/routes.rb (not here).
  # Reason: config.exceptions_app = routes uses the host's route set.
  # The host routes reference engine controllers by class path.
end
