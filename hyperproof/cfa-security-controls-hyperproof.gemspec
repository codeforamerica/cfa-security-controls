# frozen_string_literal: true

require_relative 'lib/cfa_security_controls/hyperproof/version'

Gem::Specification.new do |s|
  s.name        = 'cfa-security-controls-hyperproof'
  s.version     = CfaSecurityControls::Hyperproof::VERSION
  s.licenses    = ['MIT']
  s.summary     = 'Code for America Hyperproof Security Controls'
  s.description = 'Security & compliance control automation for Hyperproof.'
  s.authors     = ['Code for America']
  s.email       = 'infra@codeforamerica.org'
  s.files       = Dir['lib/**/*'] + Dir['Gemfile*'] + ['Rakefile']
  s.homepage    = 'https://codeforamerica.org'
  s.metadata    = {
    'bug_tracker_uri' => 'https://github.com/codeforamerica/cfa-security-controls/issues',
    'homepage_uri' => s.homepage,
    # Require privileged gem operations (such as publishing) to use MFA.
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => 'https://github.com/codeforamerica/cfa-security-controls'
  }
  s.executables << 'hyperproof'

  s.required_ruby_version = '>= 3.4'

  s.add_dependency 'aptible-api', '~> 1.9'
  s.add_dependency 'aws-sdk-configservice', '~> 1.128'
  s.add_dependency 'aws-sdk-rds', '~> 1.276'
  s.add_dependency 'aws-sdk-resourceexplorer2', '~> 1.36'
  s.add_dependency 'csv', '~> 3.3'
  s.add_dependency 'faraday', '~> 2.13'
  s.add_dependency 'faraday-multipart', '~> 1.1'
  s.add_dependency 'marcel', '~> 1.0'
  s.add_dependency 'multi_json', '~> 1.15'
  s.add_dependency 'thor', '~> 1.3'
end
