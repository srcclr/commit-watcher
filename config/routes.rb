require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  get 'notifications/index'

  resources :configurations
  resources :projects
  resources :commits
  resources :rules
  resources :rule_sets
  resources :notifications

  namespace :api, path: '', constraints: { subdomain: 'api' }, defaults: { format: :json } do
    namespace :v1 do
      resources :configurations
      resources :projects
      resources :commits do
        collection do
          get 'wipe'
        end
      end
      resources :rules
      resources :rule_sets
    end
  end

  get 'dashboard/index'
  get 'configurations/index'
  get 'projects/index'
  get 'commits/index'
  get 'rules/index'
  get 'rule_sets/index'
  get 'notifications/index'

  mount Sidekiq::Web => '/sidekiq'

  root 'dashboard#index'
end
