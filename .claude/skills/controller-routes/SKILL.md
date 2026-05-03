---
name: controller-routes
description: Add controllers and routes following project patterns for organizer namespaces, strong params, and Turbo
license: MIT
---

## What I do
- Add routes in `config/routes.rb` with nested resources
- Create controllers following organizer namespace conventions
- Write strong params using Rails 8 `params.expect`
- Handle Turbo frame requests and redirects

## When to use me
- Adding new CRUD endpoints
- Creating nested routes under organizer namespace
- Adding custom collection/member routes
- Creating public-facing endpoints

## Project Conventions

### Routes Structure
```ruby
# Public routes
resources :tournaments, only: %i[index show] do
  resources :rounds, only: [] do
    resources :pods, only: [] do
      resources :results
    end
  end
  resources :event_participants do
    collection { get "me" }
  end
end

# Organizer namespace (requires authentication + organizer role)
namespace :organizer do
  root "tournaments#index"
  
  resources :tournaments do
    resources :rounds do
      resources :pods do
        resources :results
        resources :infractions, only: %i[new create]
      end
      resources :seatings, only: [] do
        patch :swap, on: :collection
      end
    end
    resources :event_participants do
      resources :infractions, only: %i[index destroy]
    end
  end
  
  resources :leagues do
    # same nesting as tournaments
    post :create_pickup_pod, on: :member
  end
end

root "events#index"
```

### Controller Hierarchy
```
ApplicationController < ActionController::Base
  └── Organizer::OrganizerController < ApplicationController
      ├── Organizer::TournamentsController
      ├── Organizer::LeaguesController
      ├── Organizer::CircuitsController
      ├── Organizer::RoundsController
      ├── Organizer::ResultsController
      ├── Organizer::InfractionsController
      ├── Organizer::SeatingsController
      └── Organizer::EventParticipantsController
```

### Organizer Base Controller
```ruby
# app/controllers/organizer/organizer_controller.rb
module Organizer
  class OrganizerController < ApplicationController
    before_action :authorize_user!

    def authorize_user!
      redirect_to root_url, alert: "Not allowed" unless current_user.organizer?
    end

    def current_organizer
      current_user.event_organizer
    end
  end
end
```

### Controller Skeleton
```ruby
# frozen_string_literal: true

module Organizer
  class ResourceController < OrganizerController
    def index
      @items = Model.for_organizer(current_organizer).preload(:associations)
    end

    def new
      @item = Model.new
    end

    def create
      @item = Model.create(resource_params.merge(event_organizer: current_organizer))
      redirect_to [:organizer, @item], notice: "Created"
    rescue => e
      # Handle error
    end

    def edit
      @item = Model.for_organizer(current_organizer).find(params[:id])
    end

    def update
      @item = Model.for_organizer(current_organizer).find(params[:id])
      @item.attributes = resource_params
      if @item.save
        redirect_to [:organizer, @item], notice: "Updated"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @item = Model.for_organizer(current_organizer).find(params[:id])
      @item.destroy
      redirect_to index_path, notice: "Deleted"
    rescue ActiveRecord::RecordNotFound
      redirect_to index_path, alert: "Not found"
    end

    private

    def resource_params
      params.expect(resource: %i[field1 field2])
    end
  end
end
```

### Strong Params (Rails 8)
- Use `params.expect(:model, [:fields])` instead of `params.require(...).permit(...)`
- List fields as an array in one call
- Nested params: `params.expect(tournament: %i[name state])`

### Authorization Pattern
- `for_organizer(current_organizer)` scope on models for scoping
- `rescue ActiveRecord::RecordNotFound` in show/edit/update → redirect to index
- `current_organizer` helper in OrganizerController base class

### Layout Handling
- Default layout: `application`
- Modal layout: `layout "modal", only: %i[new edit]` in ApplicationController
- Turbo frame: `<%= turbo_frame_tag "modal", target: "_top" %>` in layout

### N+1 Prevention
- ApplicationController uses Prosopite (non-production only) to detect N+1 queries
- Use `preload` or `includes` in index/show actions
- Example: `.preload(rounds: :pods, event_participants: { player: :user })`

## Key Files
- `config/routes.rb` — Full routes structure
- `app/controllers/organizer/organizer_controller.rb` — Auth base class
- `app/controllers/organizer/tournaments_controller.rb` — Example controller with strong params
- `app/controllers/concerns/authentication.rb` — Auth concern
