# Base image with Ruby 3.3.6
FROM ruby:3.3.6

# Install dependencies
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  nodejs \
  yarn \
  postgresql-client-16

# Set working directory
WORKDIR /app

# Install bundler
COPY Gemfile Gemfile.lock /app/
RUN gem install bundler && bundle install

# Install node modules (for TailwindCSS)
COPY package.json yarn.lock /app/
RUN yarn install

# Copy application code
COPY . /app/

# Precompile assets (TailwindCSS included)
RUN bundle exec rake assets:precompile

# Command to run the Rails app
CMD ["rails", "server", "-b", "0.0.0.0"]
