Rails.application.routes.draw do
  get 'holds/create'
  get 'holds/show'
  get 'trips/index'
  get 'trips/show'
  devise_for :users

  root "trips#index"

  resources :trips, only: [:index, :show] do
    resources :holds, only: [:create]
  end

  resources :holds, only: [:show]

  resources :bookings, only: [:index, :show, :create, :destroy] do
    member do
      get :reschedule
      patch :update_reschedule
    end
  end

end
