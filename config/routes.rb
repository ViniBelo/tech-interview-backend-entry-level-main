require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'

  # Carts
  resource :cart, only: %i[show create], controller: :carts do
    post "/add_item" => "carts#add_item"
    delete "/:product_id" => "carts#remove_item"
  end

  resources :products
  get "up" => "rails/health#show", as: :rails_health_check

  root "rails/health#show"
end
