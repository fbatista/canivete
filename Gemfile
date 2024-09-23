# frozen_string_literal: true

source 'https://rubygems.org'

gem 'rails', '~> 7.2.1'

gem 'bootsnap', require: false
gem 'jbuilder'
gem 'tzinfo-data', platforms: %i[windows jruby]

gem 'hotwire-rails'
gem 'importmap-rails'
gem 'sprockets-rails'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'tailwindcss-rails'

gem 'bcrypt'
gem 'pg'
gem 'activerecord-postgis-adapter', git: 'https://github.com/rgeo/activerecord-postgis-adapter.git'
gem 'puma', '>= 5.0'
gem 'redis', '>= 4.0.1'

gem 'devise'

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
