# frozen_string_literal: true

require 'concurrent-ruby'
require 'configsl'

module CfaSecurityControls
  module Hyperproof
    # Configuration for the Hyperproof integration.
    class Config < ConfigSL::Config
      option :log_level, type: Symbol, default: :info,
                         values: %i[debug info warn error]

      option :aptible_username, type: String
      option :aptible_password, type: String
      option :hyperproof_client_id, type: String, required: true
      option :hyperproof_client_secret, type: String, required: true
      option :threads_min, type: Integer, default: 1
      option :threads_max, type: Integer, default: Concurrent.processor_count
      option :theads_queue_size, type: Integer, default: 10

      def initialize(params = {})
        super
        validate!
      end

      def logger
        @logger ||= Logger.new($stdout, level: log_level)
      end

      def thread_pool
        @thread_pool ||= Concurrent::ThreadPoolExecutor.new(
          min_threads: threads_min,
          max_threads: threads_max,
          max_queue: theads_queue_size,
          fallback_policy: :caller_runs
        )
      end
    end
  end
end
