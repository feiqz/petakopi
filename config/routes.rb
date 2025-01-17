Rails.application.routes.draw do
  authenticate :user, ->(user) { user.admin? } do
    require "sidekiq/web"

    mount Sidekiq::Web => "/sidekiq"
  end

  devise_for :users

  namespace :admin do
    resources :coffee_shops
  end

  get "directories/:state(/:district)" => "directories#index", as: "directories"

  resources :locations do
    collection do
      get :cities
    end
  end

  get "about" => "pages#about"
  get "map" => "map#index"

  namespace :api do
    namespace :v1 do
      resources :coffee_shops, only: [:index]
    end
  end

  direct :rails_public_blob do |blob|
    if blob.signed_id.nil?
      ""
    elsif Rails.env.development? || Rails.env.test?
      route_for(:rails_blob, blob)
    else
      File.join("https://assets.petakopi.my", blob.key)
    end
  end

  resources :coffee_shops, only: [:new, :create]

  get "/coffee_shops/:id", to: redirect("/%{id}", status: 301)
  get "/cs/:id", to: redirect("/%{id}", status: 301)

  constraints CoffeeShopConstraint.new do
    resources :coffee_shops, path: "", only: [:show]
  end

  root "coffee_shops#index"
end
