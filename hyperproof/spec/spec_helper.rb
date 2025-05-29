# frozen_string_literal: true

# Configure code coverage reporting.
if ENV.fetch('COVERAGE', false)
  require 'simplecov'

  SimpleCov.minimum_coverage 95
  SimpleCov.start do
    add_filter '/spec/'
    add_filter 'lib/cfa_security_controls/hyperproof/version.rb'

    track_files 'lib/**/*.rb'
  end
end

# Include the gem and test helpers.
require_relative '../lib/cfa-security-controls-hyperproof'
require_relative 'support/helpers'

RSpec.configure do |config|
  # Keep the original $stderr and $stdout so that we can suppress output during
  # tests.
  original_stderr = $stderr
  original_stdout = $stdout

  config.include Helpers::Config

  config.before do
    # Clear the configuration before each test.
    stub_const('ENV', default_config_env)
    clear_config
    allow(File).to receive(:exist?).and_call_original
  end

  config.before(:all) do
    # Suppress logger output.
    $stderr = File.new(File::NULL, 'w')
    $stdout = File.new(File::NULL, 'w')
  end

  config.after(:all) do
    # Restore the original $stderr and $stdout after all tests.
    $stderr = original_stderr
    $stdout = original_stdout
  end
end

# Include supporting resources.
require_relative 'support/examples'
