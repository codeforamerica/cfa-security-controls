# frozen_string_literal: true

require_relative '../clients/hyperproof'

module CfaSecurityControls
  module Hyperproof
    module Entities
      # Represents a label in Hyperproof.
      class Label
        class NotFound < ArgumentError; end

        attr_reader :name

        # Initialize a new label.
        #
        # @param name [String] The name of the label.
        def initialize(name)
          @name = name
        end

        # Create a new label.
        #
        # If the label already exists, this method will return the existing label.
        #
        # @return [Hash] The newly created or existing label.
        def create
          return label if exists?

          @label = client.create_label(name:)
        end

        # Check if the label exists.
        #
        # @return [Boolean] True if the label exists, false otherwise.
        def exists?
          label
          true
        rescue NotFound
          false
        end

        # Get the label ID.
        #
        # @return [String] The ID of the label.
        def id
          label[:id]
        end

        private

        # Get the client for Hyperproof.
        #
        # @return [Clients::Hyperproof] The Hyperproof client.
        def client
          @client ||= Clients::Hyperproof.new
        end

        # Get the label from Hyperproof.
        #
        # @return [Hash] The label data.
        #
        # @raise [NotFound] If the label is not found.
        def label
          @label ||= client.labels.find { |label| label[:name] == @name }
          raise NotFound, "Label '#{@name}' not found" unless @label

          @label
        end
      end
    end
  end
end
