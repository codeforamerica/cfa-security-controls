# frozen_string_literal: true

require 'aptible/api'
require 'multi_json'

module CfaSecurityControls
  module Hyperproof
    module Clients
      # Client for Aptible.
      class Aptible
        class InvalidCredentials < ArgumentError; end

        TOKEN_FILE = File.join(Dir.home, '.aptible', 'tokens.json')

        # Retrieve all databases from Aptible.
        #
        # @return [Array<::Aptible::Api::Database>] An array of databases.
        def databases
          ::Aptible::Api::Database.all(token:)
        end

        private

        # Configuration for the system.
        #
        # @return [Config]
        def config
          @config ||= CfaSecurityControls::Hyperproof.config
        end

        # Retrieve a token to authenticate with Aptible.
        #
        # This method uses a chain to find the first valid set of credentials:
        #
        # 1. Attempt to use `APTIBLE_USERNAME` and `APTIBLE_PASSWORD`
        #    environment variables.
        # 2. Check for the Aptible SSO token file at `~/.aptible/tokens.json`.
        #
        # If no valid credentials are found, an error is raised.
        #
        # @return [String] The token for the Aptible API.
        #
        # @raise [InvalidCredentials] If no valid credentials are found.
        def token
          @token ||= basic_auth_token || sso_token

          raise InvalidCredentials, 'No valid Aptible credentials found' unless @token

          @token
        end

        # Retrieve the SSO token from the Aptible token file.
        #
        # @return [String, Boolean] The SSO token for the Aptible API, or false
        #   if the token isn't set.
        def sso_token
          return false unless File.exist?(TOKEN_FILE)

          contents = JSON.parse(File.read(TOKEN_FILE))
          return false unless contents.key?(
            ::Aptible::Auth.configuration.root_url
          )

          contents[::Aptible::Auth.configuration.root_url]
        end

        # Retrieve a basic auth token to authenticate with Aptible.
        #
        # @return [Aptible::Auth::Token, Boolean] The token for the Aptible API,
        #   or false if the credentials aren't present.
        def basic_auth_token
          return false unless config.aptible_username && config.aptible_password

          ::Aptible::Auth::Token.create(email: config.aptible_username,
                                        password: config.aptible_password,
                                        headers: { 'Authorization' => nil })
        rescue OAuth2::Error
          false
        end
      end
    end
  end
end
