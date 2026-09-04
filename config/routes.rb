require "sidekiq/web"

Rails.application.routes.draw do
  root "practitioners#index"

  resources :practitioners, only: [:index, :show] do
    resources :appointments, only: [:create]
  end

  namespace :api do
    resources :practitioners, only: [:index, :show]
  end

  # Health check used by Heroku, and later by whatever replaces it.
  get "up" => "rails/health#show", as: :rails_health_check

  Sidekiq::Web.use Rack::Auth::Basic do |user, password|
    ActiveSupport::SecurityUtils.secure_compare(user, ENV.fetch("SIDEKIQ_WEB_USER", "admin")) &
      ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch("SIDEKIQ_WEB_PASSWORD", "changeme"))
  end
  mount Sidekiq::Web => "/sidekiq"
end
