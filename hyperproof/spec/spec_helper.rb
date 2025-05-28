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

# Include the gem.
require_relative '../lib/cfa-security-controls-hyperproof'

# Include supporting resources.
require_relative 'support/examples'
