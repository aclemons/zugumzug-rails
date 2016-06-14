Rails.application.routes.draw do

  # index show new edit create update destroy

  root to: 'static_pages#home'
  get    'help'    => 'static_pages#help'
  get    'about'   => 'static_pages#about'

  devise_for :users, :controllers => { sessions: 'sessions', registrations: 'registrations' }

  resources :users,   only: [ :index, :show ]
  resources :cities,  only: [ :index, :show ]
  resources :games,   only: [ :index, :show, :new, :create, :update ] do
    resources :players, only: [ :create ] do
      # TODO move to own controllers
      delete    'destination_tickets'          => 'players#discard_destination_tickets'
      patch     'destination_tickets/assign'   => 'players#draw_destination_tickets'
      patch     'train_cards(/:train_card_id)' => 'players#draw_train_card'
      post      'routes/'                      => 'players#build_route'
    end
  end
end
