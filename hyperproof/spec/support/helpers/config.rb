# frozen_string_literal: true

module Helpers
  # Test helpers for system configuration.
  module Config
    # Clear the current configuration.
    def clear_config
      CfaSecurityControls::Hyperproof.instance_variable_set(:@config, nil)
    end

    # Default configuration environment variables.
    #
    # This is useful for tests that need to override the environment, but need
    # the configuration to be valid.
    #
    # @return [Hash] A hash of environment variables.
    def default_config_env
      {
        'APTIBLE_PASSWORD' => 'aptible_password',
        'APTIBLE_USERNAME' => 'aptible_username',
        'HYPERPROOF_CLIENT_ID' => 'hyperproof_client_id',
        'HYPERPROOF_CLIENT_SECRET' => 'hyperproof_client_secret'
      }
    end

    # Force the configuration to be valid without actually validating it.
    #
    # This is useful for tests that need to run without a valid configuration
    # but still want to avoid validation errors.
    #
    # rubocop:disable RSpec/AnyInstance
    def force_valid_config
      allow_any_instance_of(CfaSecurityControls::Hyperproof::Config).to \
        receive(:validate!).and_return(true)
    end
    # rubocop:enable RSpec/AnyInstance

    # Set the configuration for the system.
    #
    # @param options [Hash] Options to set in the configuration.
    # @return [CfaSecurityControls::Hyperproof::Config] The configuration object.
    def set_config(options = {})
      config = CfaSecurityControls::Hyperproof::Config.new(options)
      CfaSecurityControls::Hyperproof.config(config)
      config
    end
  end
end
