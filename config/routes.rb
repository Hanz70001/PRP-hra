Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  #main universal page route
  root 'home#redirect_to_dashboard'
  get 'dashboard', to: 'dashboard#show'
  post 'data_incoming', to: 'ajax#data_incoming'
  post 'query_incoming', to: 'ajax#query_incoming'
end
