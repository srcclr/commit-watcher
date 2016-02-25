require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do

  resources :configurations
  resources :projects
  resources :commits

  get 'dashboard/index'
  get 'configurations/index'
  get 'projects/index'
  get 'commits/index'

  mount Sidekiq::Web => '/sidekiq'

  root 'dashboard#index'
end
