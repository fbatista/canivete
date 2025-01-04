# frozen_string_literal: true

source 'https://rubygems.org'

# Backend
gem 'rails', '~> 8'
gem 'bootsnap', require: false
gem 'jbuilder'
gem 'tzinfo-data', platforms: %i[windows jruby]
gem 'devise'
gem 'kaminari'
gem 'kamal', require: false
gem 'thruster', require: false

# Frontend
gem 'propshaft'
gem 'hotwire-rails'
gem 'importmap-rails'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'tailwindcss-rails'
gem 'commonmarker'

# Databases
gem 'activerecord-postgis-adapter', git: 'https://github.com/fbatista/activerecord-postgis-adapter.git'
gem 'bcrypt'
gem 'pg'
gem 'puma', '>= 5.0'
gem 'solid_cache'
gem 'solid_queue'
gem 'solid_cable'

group :development, :test do
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'brakeman', require: false
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails-omakase', require: false
end

group :development do
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
end
