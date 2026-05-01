# frozen_string_literal: true

require 'simplecov'

SimpleCov.start 'rails' do
  # Use a unique name for each parallel worker
  command_name "Job #{ENV['TEST_ENV_NUMBER']}" if ENV['TEST_ENV_NUMBER']
  
  # Optional: filter out specific directories
  add_filter '/bin/'
  add_filter '/db/'
  add_filter '/test/'
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

# Allow WebMock to work with Selenium for system tests
WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # SimpleCov Parallel Setup
    parallelize_setup do |worker|
      SimpleCov.command_name "#{SimpleCov.command_name}-worker-#{worker}"
    end

    parallelize_teardown do |worker|
      SimpleCov.result
    end

    # Setup all fixtures in test/fixtures/*.yml
    fixtures :all

    setup do
      # Note: Ensure Event is loaded; sometimes resetting counters 
      # on a model here can trigger early loading.
      Event.reset_counters if defined?(Event)
    end
  end
end