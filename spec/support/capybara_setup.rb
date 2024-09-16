require "capybara/rspec"
require "selenium-webdriver"

if ENV["DOCKERIZED"]
  Capybara.app_host = "http://#{IPSocket.getaddress(Socket.gethostname)}:3010"
  Capybara.server_host = "0.0.0.0"
  Capybara.server_port = "3010"
  Capybara.always_include_port = true
  Capybara.default_driver = :remote_selenium
  Capybara.javascript_driver = :remote_selenium

  RSpec.configure do |config|
    config.before(:each, type: :system) do
      driven_by :selenium, using: :firefox, screen_size: [1400, 1400], options: {
        browser: :remote,
        url: "http://firefox:4444"
      }
    end
  end
else
  RSpec.configure do |config|
    config.before(:each, type: :system) do
      browser = ENV.fetch("JS_DRIVER", :headless_chrome).downcase.to_sym
      driven_by :selenium, using: browser, screen_size: [1920, 1080] do |driver_options|
        driver_options.add_argument("disable-search-engine-choice-screen")
      end
    end
  end
end
