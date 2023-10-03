# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  resources :tournaments do
    resources :rounds do
      resources :pods do
        resources :results
      end
    end

    resources :tournament_participants
  end
  root 'tournaments#index'
end
