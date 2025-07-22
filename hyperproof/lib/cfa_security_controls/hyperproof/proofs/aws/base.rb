# frozen_string_literal: true

require 'aws-sdk-configservice'

require_relative '../proof'

module CfaSecurityControls
  module Hyperproof
    module Proofs
      module AWS
        # Base class for AWS proofs.
        class Base < Proof
          AGGREGATOR_NAME = 'aws-controltower-GuardrailsComplianceAggregator'

          # Collect the evidence for this proof.
          #
          # @return [Array<Hash>] The collected evidence.
          def collect
            client = Aws::ConfigService::Client.new
            response = client.select_aggregate_resource_config(
              configuration_aggregator_name: AGGREGATOR_NAME,
              expression:
            )

            format(response)
          end

          private

          # Defines the resource type for AWS Config.
          #
          # @return [String] The resource type.
          #
          # # @raise [NotImplementedError] If the method is not overridden.
          def resource_type
            raise NotImplementedError, 'This method should be overridden'
          end

          # Fields to select for the resources from AWS Config.
          #
          # @return [Array<String>] The fields to select.
          def fields
            %w[accountId resourceId awsRegion availabilityZone resourceName arn
               tags]
          end

          # Mapping of AWS Config field names to the desired output field names.
          #
          # @return [Hash{String => Symbol}] The mapping of field names.
          def field_map
            {}
          end

          # AWS Config expression to select the relevant data.
          #
          # @return [String] The AWS Config expression.
          def expression
            <<~SQL
              SELECT #{fields.join(', ')}
              WHERE
                resourceType = '#{resource_type}'
            SQL
          end

          # Format the response from the AWS Config service.
          #
          # @param response [Seahorse::Client::Response] The response from the
          #   AWS Config service.
          # @return [Array<Hash>] The formatted response.
          def format(response)
            response.results.map do |result|
              data = JSON.parse(result, symbolize_names: true)
              data.delete(:configuration).each do |k, v|
                data["configuration.#{k}"] = v
              end
              data.transform_keys! { |k| field_map[k] || k }
            end
          end
        end
      end
    end
  end
end
