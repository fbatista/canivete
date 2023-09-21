# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

gem 'rails', '~> 7'

gem 'bootsnap', require: false
gem 'jbuilder'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

gem 'hotwire-rails'
gem 'importmap-rails'
gem 'sprockets-rails'
gem 'tailwindcss-rails'

gem 'bcrypt'
gem 'dotenv-rails', '~> 2.8', require: 'dotenv/rails-now', group: %i[development test]
gem 'pg'
gem 'puma'
gem 'redis'

gem 'devise'

group :development, :test do
  gem 'debug'
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
  gem 'webdrivers'
end
