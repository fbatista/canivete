# frozen_string_literal: true

Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :registrations, only: %i[new create]

  resources :tournaments, only: %i[index show] do
    resources :rounds do
      resources :pods
    end

    resources :event_participants do
      collection do
        get "me"
      end
    end
  end

  resources :leagues, only: %i[index show] do
    resources :rounds do
      resources :pods
    end

    resources :event_participants do
      collection do
        get "me"
      end
    end
  end

  resources :events, only: %i[index]
  resources :circuits, only: %i[index show]

  namespace :organizer do
    root "tournaments#index"

    resources :tournaments do
      resources :infractions, only: %i[new create]
      resources :event_participants do
        resources :infractions, only: %i[index destroy]
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

    resources :leagues do
      resources :infractions, only: %i[new create]
      resources :event_participants do
        resources :infractions, only: %i[index destroy]
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
      post :create_pickup_pod, on: :member
    end

    resources :circuits do
      resources :tournaments, only: %i[new create]
    end
  end

  root "events#index"
end
