# frozen_string_literal: true

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "active_support/testing/time_helpers"

RSpec.configure do |config|
  include ActiveSupport::Testing::TimeHelpers

  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.before do
    travel_to Time.zone.parse("2026-06-16T10:00:00Z") # Tuesday, within business hours
  end

  config.after do
    travel_back
  end
end
