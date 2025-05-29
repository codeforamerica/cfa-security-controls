# frozen_string_literal: true

require 'faraday'
require 'faraday/multipart'
require 'marcel'

module CfaSecurityControls
  module Hyperproof
    module Clients
      # Client for Hyperproof.
      class Hyperproof
        class Unauthorized < ArgumentError; end

        MULTI_PART_HEADERS = {
          'Content-Type' => 'multipart/form-data'
        }.freeze

        # Create a new label.
        #
        # @param name [String] The name of the label.
        # @param description [String] The description of the label.
        # @return [Hash] The newly created label.
        def create_label(name:, description: nil)
          conn.post('labels', { name:, description: }).body
        end

        # Retrieve labels from Hyperproof.
        #
        # @return [Array<Hash>] An array of labels.
        def labels
          conn.get('labels').body
        end

        # Create a new proof.
        #
        # @param name [String] The name of the proof; should be a filename.
        # @param file [String] The file to upload as the proof.
        # @param label [Label] The label associated with the proof, if any.
        # @return [Hash] The newly created proof.
        def create_proof(name:, file:, label: nil)
          path = label.nil? ? 'proof' : "labels/#{label.id}/proof"
          params = {
            proof: Faraday::UploadIO.new(
              file,
              Marcel::MimeType.for(Pathname.new(file)),
              name
            )
          }

          conn.post(path, params, MULTI_PART_HEADERS).body
        end

        # Create a new version of an existing proof.
        #
        # @param id [String] The ID of the proof.
        # @param name [String] The name of the proof; should be a filename.
        # @param file [String] The file to upload as the proof.
        # @return [Hash] The newly created proof version.
        def create_proof_version(id:, name:, file:)
          params = {
            proof: Faraday::UploadIO.new(
              file,
              Marcel::MimeType.for(Pathname.new(file)),
              name
            )
          }

          conn.post("proof/#{id}/versions", params, MULTI_PART_HEADERS).body
        end

        # Retrieve and paginate through proofs.
        #
        # When no block is passed, this method returns an array of all proofs.
        # When a block is passed, it yields each proof to the block and
        # returns an array of the results. If you don't wish for your block's
        # return value to be included in the final array, make sure it returns
        # `nil`.
        #
        # @param params [Hash] params The parameters to pass to the API.
        # @option params [String] :objectType The type of linked object to
        #   filter on.
        # @option params [String] :objectId The ID of the linked object to
        #   filter on.
        # @return [Array] An array of proofs.
        def proofs(params = {})
          proofs = []
          loop do
            response = conn.get('proof', params).body
            response[:data].each do |proof|
              proofs << (block_given? ? yield(proof) : proof)
            end

            break proofs if response[:nextToken].nil?

            params[:nextToken] = response[:nextToken]
          end.compact
        end

        private

        # Configuration for the system.
        #
        # @return [Config]
        def config
          @config ||= CfaSecurityControls::Hyperproof.config
        end

        # Establish a connection to the Hyperproof API.
        #
        # @return [Faraday::Connection] The Faraday connection object.
        def conn
          @conn = Faraday.new 'https://api.hyperproof.app/v1/' do |conn|
            conn.request :multipart
            conn.request :json
            conn.response :json, parser_options: { symbolize_names: true }
            conn.headers = {
              'Content-Type' => 'application/json',
              'Authorization' => "Bearer #{auth_token}"
            }
          end
        end

        # Retrieve an authentication token for the Hyperproof API.
        #
        # @return [String] The authentication token.
        def auth_token
          unless config.hyperproof_client_id && config.hyperproof_client_secret
            raise Unauthorized, 'Missing Hyperproof credentials'
          end

          response = Faraday.post(
            'https://accounts.hyperproof.app/oauth/token',
            {
              client_id: config.hyperproof_client_id,
              client_secret: config.hyperproof_client_secret,
              grant_type: 'client_credentials'
            }.to_json,
            {
              'Content-Type' => 'application/json'
            }
          )

          raise Unauthorized, "Error: #{response.status} - #{response.body}" unless response.success?

          JSON.parse(response.body, symbolize_names: true)[:access_token]
        end
      end
    end
  end
end
