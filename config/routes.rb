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
      resources :tournament_participants
      resources :rounds do
        resources :pods do
          resources :results
        end
      end
    end
  end

  root 'tournaments#index'
end
