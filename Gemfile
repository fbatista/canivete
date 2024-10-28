# frozen_string_literal: true

source 'https://rubygems.org'

# Backend
gem 'rails', '~> 7.2.1'
gem 'bootsnap', require: false
gem 'jbuilder'
gem 'tzinfo-data', platforms: %i[windows jruby]
gem 'devise'

# Frontend
gem 'hotwire-rails'
gem 'importmap-rails'
gem 'sprockets-rails'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'tailwindcss-rails'
gem 'commonmarker'

# Databases
gem 'activerecord-postgis-adapter', git: 'https://github.com/rgeo/activerecord-postgis-adapter.git'
gem 'bcrypt'
gem 'pg'
gem 'puma', '>= 5.0'
gem 'redis', '>= 4.0.1'
gem 'solid_queue', '~> 1.0'

group :development, :test do
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'brakeman', require: false
  gem 'rubocop-rails-omakase', require: false
end

group :development do
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'web-console'
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'selenium-webdriver'
end
