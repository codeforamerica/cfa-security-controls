# frozen_string_literal: true

require 'configsl'

module CfaSecurityControls
  module Hyperproof
    # Configuration for the Hyperproof integration.
    class Config < ConfigSL::Config
      option :log_level, type: Symbol, default: :info,
                         values: %i[debug info warn error]

      option :aptible_username, type: String, required: true
      option :aptible_password, type: String, required: true
      option :hyperproof_client_id, type: String, required: true
      option :hyperproof_client_secret, type: String, required: true

      def logger
        @logger ||= Logger.new($stdout, level: log_level)
      end
    end
  end
end
