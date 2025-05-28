# frozen_string_literal: true

require_relative '../clients/hyperproof'

module CfaSecurityControls
  module Hyperproof
    module Entities
      # Represents a proof in Hyperproof.
      class Proof
        class NotFound < ArgumentError; end

        attr_reader :label, :name

        # Initialize a new proof.
        #
        # @param name [String] The name of the proof; should be a filename.
        # @param label [Label] The label associated with the proof, if any.
        def initialize(name, label: nil)
          @name = name
          @label = label
        end

        # Create a new proof.
        #
        # If the proof already exists, this method will update the existing proof
        # with a new version.
        #
        # @param file [String] The file to upload as the proof.
        # @return [Hash] The newly created or updated proof.
        def create(file)
          @proof = if exists?
                     client.create_proof_version(id:, name:, file:)
                   else
                     client.create_proof(name:, file:, label:)
                   end
        end

        # Check if the proof exists.
        #
        # @return [Boolean] True if the proof exists, false otherwise.
        def exists?
          proof
          true
        rescue NotFound
          false
        end

        # Get the proof ID.
        #
        # @return [String] The ID of the proof.
        def id
          proof[:id]
        end

        # Get the current version of the proof.
        #
        # @return [Integer] The version of the proof.
        def version
          proof[:version]
        end

        private

        # Get the client for Hyperproof.
        #
        # @return [Clients::Hyperproof] The Hyperproof client.
        def client
          @client ||= Clients::Hyperproof.new
        end

        # Retrieve the proof from Hyperproof.
        #
        # @return [Hash] The proof data.
        #
        # @raise [NotFound] If the proof is not found.
        def proof
          return @proof if @proof

          params = @label.nil? ? {} : { objectType: :label, objectId: @label.id }
          results = client.proofs(params) { |p| break p if p[:filename] == @name }

          raise NotFound, "Proof '#{@name}' not found" if results.nil? || results.empty?

          @proof = results
        end
      end
    end
  end
end
