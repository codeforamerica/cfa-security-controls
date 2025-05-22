# frozen_string_literal: true

require 'aptible/api'

module CfaSecurityControls
  module Hyperproof
    module Clients
      # Client for Aptible.
      class Aptible
        TOKEN_FILE = File.join(Dir.home, '.aptible', 'tokens.json')

        # Retrieve all databases from Aptible.
        #
        # @return [Array<::Aptible::Api::Database>] An array of databases.
        def databases
          ::Aptible::Api::Database.all(token:)
        end

        private

        # Retrieve a token to authenticate with Aptible.
        #
        # @return [String] The token for the Aptible API.
        #
        # @todo Support running in CI where we don't have an SSO token file.
        def token
          @token ||= JSON.parse(File.read(TOKEN_FILE))[::Aptible::Auth.configuration.root_url]
        end
      end
    end
  end
end
