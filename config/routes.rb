# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  resources :tournaments, only: %i[index show] do
    resources :rounds do
      resources :pods do
        resources :results
      end
    end

    resources :tournament_participants do
      collection do
        get 'me'
      end
    end
  end

  namespace :organizer do
    resources :tournaments do
      resources :infractions, only: %i[new create]
      resources :tournament_participants do
        resources :infractions, only: %i[index]
      end
      resources :rounds do
        resources :seatings, only: [] do
          patch :swap, on: :collection
        end
        resources :pods do
          resources :results
          resources :infractions, only: %i[new create]
        end
      end
    end
  end

  root 'tournaments#index'
end
