require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  resources :projects
  resources :configurations

  get 'dashboard/index'
  get 'projects/index'
  get 'configurations/index'

  mount Sidekiq::Web => '/sidekiq'

  root 'dashboard#index'
end
