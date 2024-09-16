require "rails_helper"
require "vcr"

def default_vcr_record_option
  ENV["CI"].present? ? :none : :once
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.ignore_localhost = true
  config.ignore_hosts "firefox"
  config.filter_sensitive_data("<STRIPE-PK>") do
    Rails.application.credentials.dig(:stripe, :private)
  end

  config.default_cassette_options = {
    match_requests_on: %i[method uri body],
    record: default_vcr_record_option,
    erb: true
  }
  # Avoid storing body as binary (ensure it's always readable)
  config.before_record do |i|
    i.response.body.force_encoding("UTF-8")
  end
end

RSpec.configure do |config|
  config.around(:each, vcr: false) do |example|
    WebMock.disable_net_connect! do
      VCR.turned_off { example.call }
    end
  end
end
