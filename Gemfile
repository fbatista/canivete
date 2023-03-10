source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.1"

gem "rails", "~> 7"

gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
gem "jbuilder"

gem "sprockets-rails"
gem "importmap-rails"
gem "hotwire-rails"
gem "tailwindcss-rails"

gem "dotenv-rails", "~> 2.8", require: "dotenv/rails-now", group: [:development, :test]
gem "puma"
gem "pg"
gem "bcrypt"
gem "redis"

gem "devise"

group :development, :test do
  gem "debug"
end

group :development do
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end
