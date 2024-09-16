# Simplecov needs to be started before loading additional files.
require "support/simplecov_setup"
require "support/vcr_setup"
require "support/capybara_setup"
require "support/helpers/logging"
require "support/helpers/models/scraped_swatch"
require "support/feature_flags_helper"
require "view_component/test_helpers"

# See https://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.include Helpers::Logging
  config.include Helpers::Models::ScrapedSwatch
  config.include RequestHelper, type: :request
  config.include FeatureFlagsHelper
  config.include ViewComponent::TestHelpers, type: :component

  # set RSpec 4 defaults
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  # https://relishapp.com/rspec/rspec-core/docs/configuration/zero-monkey-patching-mode
  config.disable_monkey_patching!

  # This allows you to limit a spec run to individual examples or groups
  # you care about by tagging them with `:focus` metadata. When nothing
  # is tagged with `:focus`, all examples get run. RSpec also provides
  # aliases for `it`, `describe`, and `context` that include `:focus`
  # metadata: `fit`, `fdescribe` and `fcontext`, respectively.
  config.filter_run_when_matching :focus

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = "doc"
  end

  config.order = :random
  # skip Truemail validation for tests
  config.before { allow(Truemail).to receive_message_chain(:validate, :result, :success).and_return(true) }

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  # config.example_status_persistence_file_path = "spec/examples.txt"

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  # config.profile_examples = 10

  # Avoid stdout, stderr printing when running these examples.
  config.before(:each, :no_output) do
    allow($stdout).to receive(:puts)
    $stderr = StringIO.new
  end

  config.after(:each, :no_output) do
    $stderr = STDERR
  end
end
