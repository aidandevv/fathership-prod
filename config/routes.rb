Rails.application.routes.draw do
  get 'about/index'
  resources :chats
  
  devise_for :users do
    get '/users/sign_out' => 'devise/sessions#destroy'
  end
  
  get 'user_account/account_modification'
  get 'chat/index', to: 'chat#index', as: 'chat_index'
  get 'home/landing'
  get 'about', to: 'about#index'
  get 'contact', to: 'contact#index'
  get 'support', to: 'support#index'  # Add this line to map /support to support#index

  # Remove custom routes for sessions and users that conflict with Devise
  # get 'sessions/new'
  # get 'sessions/create'
  # get 'sessions/destroy'
  # get 'users/new'
  # get 'users/create'

  # If you need custom sign-up and login routes, ensure they don't conflict with Devise
  # get 'signup', to: 'users#new', as: 'signup'
  # post 'signup', to: 'users#create'
  # get 'login', to: 'sessions#new', as: 'login'
  # post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy', as: 'logout'

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#landing"
end
