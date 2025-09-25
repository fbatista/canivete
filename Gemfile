# frozen_string_literal: true

source "https://rubygems.org"

# Backend
gem "rails", "~> 8.0.3"
gem "bootsnap", require: false
gem "jbuilder"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "kaminari"
gem "kamal", require: false
gem "thruster", require: false

# Frontend
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 4.3"
gem "commonmarker"
gem "reactionview", "~> 0.1.2"
gem "herb", force_ruby_platform: RUBY_PLATFORM.include?("darwin")

# Databases
gem "activerecord-postgis-adapter"
gem "bcrypt"
gem "pg"
gem "puma", ">= 5.0"
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "prosopite"
gem "pg_query"

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webmock"
end
