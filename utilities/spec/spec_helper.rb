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
# require 'capybara-screenshot/rspec'
require 'rack/test'
require 'axe-rspec'
require 'axe-capybara'
require 'capybara/dsl'
require 'capybara/session'

require_relative './spec_summary'

# This is the root of the repository, e.g. the bjc-r directory
# Update this is you move this file.
REPO_ROOT = File.expand_path('../../', __dir__)

# https://nts.strzibny.name/how-to-test-static-sites-with-rspec-capybara-and-webkit/
class StaticSite
  attr_reader :root, :server

  # TODO: Rack::File will be deprecated soon. Find a better solution.
  def initialize(root)
    @root = root
    @server = Rack::File.new(root)
  end

  def call(env)
    # Remove the /bjc-r prefix, which is present in all URLs, but not in the file system.
    path = env['PATH_INFO'].gsub('/bjc-r', '')


    # Use index.html for / paths
    if path == '/' && exists?('index.html')
      env['PATH_INFO'] = '/index.html'
    elsif !exists?(path) && exists?(path + '.html')
      env['PATH_INFO'] = "#{path}.html"
    else
      env['PATH_INFO'] = path
    end

    server.call(env)
  end

  def exists?(path)
    File.exist?(File.join(root, path))
  end
end

# Capybara::Screenshot.prune_strategy = :keep_last_run

# Setup for Capybara to serve static files served by Rack
Capybara.server = :webrick
Capybara.app = Rack::Builder.new do
  map '/' do
    use Rack::Lint
    run StaticSite.new(REPO_ROOT)
  end
end.to_app

Capybara.save_path = File.join(REPO_ROOT, 'tmp')

Capybara.register_driver :chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  # macbook air ~13" screen width
  options.add_argument('--window-size=1280,2500')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

# Should be :chrome_headless in CI though.
Capybara.default_driver = :chrome_headless
Capybara.javascript_driver = :chrome_headless

# Capybara::Screenshot.register_driver(:chrome_headless) do |driver, path|
#   driver.save_screenshot(path, full: true)
# end

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

  # config.after(:suite) do
  #   # defined in the spec_summary file
  #   print_summary
  # end
end
