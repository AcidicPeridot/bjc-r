# frozen_string_literal: true

# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# See https://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration

require 'rspec'
require 'rack'

require 'capybara/rspec'
require 'rack/test'
require 'axe-rspec'
require 'axe-capybara'
require 'capybara/dsl'
require 'capybara/session'
require 'capybara-screenshot'

# Used to set the path for a local webserver.
# For simplicity, this is one level above bjc-r/ so the prefix is easily handled.
FILE_SERVER_ROOT = File.expand_path("../../../", __dir__)

Capybara.register_driver :chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  # MacBook Air ~13" screen size, with an absurd height to capture more content.
  options.add_argument('--window-size=1280,4000')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

# Change default_driver to :selenium_chrome if you want to actually see the tests running in a browser locally.
# Should be :chrome_headless in CI though.
Capybara.default_driver = :chrome_headless
Capybara.javascript_driver = :chrome_headless

Capybara::Screenshot.register_driver(:chrome_headless) do |driver, path|
  driver.save_screenshot(path)
end

Capybara::Screenshot.register_filename_prefix_formatter(:rspec) do |example|
  # Highly specific to a11y specs: path-mode-wcag-version
  # TODO: Find a nice way to name "index" pages, or consider using Capybara.page.title
  page = example.example_group.top_level_description.gsub(' is accessible', '')
  # mode = example.example_group.description # i.e. light mode / dark mode
  standard = example.description.split.last # i.e "meets WCAG 2.1"
  test_case = "#{page}_#{standard}".gsub(%r{^/}, '').gsub(%r{[/\s+]}, '-')
  "screenshot_#{test_case}"
end

Capybara.save_path = 'tmp/capybara/'
Capybara::Screenshot.autosave_on_failure = true
Capybara::Screenshot.append_timestamp = false
Capybara::Screenshot.prune_strategy = :keep_last_run

# Use Rack to serve static files from within the build directory.
# This supports "clean" URLs which serve /path/ from /path/index.html
Capybara.server = :webrick
Capybara.app = Rack::Builder.new do
  use Rack::Lint
  use Rack::Static, { urls: [''], root: "#{FILE_SERVER_ROOT}/", index: 'index.html' }
  run Rack::Files.new(FILE_SERVER_ROOT)
end.to_app

RSpec.configure do |config|
  config.include Capybara::DSL

  # Allow rspec to use `--only-failures` and `--next-failure` flags
  # Ensure that `tmp` is in your `.gitignore` file
  config.example_status_persistence_file_path = 'tmp/rspec-failures.txt'

  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups
end
