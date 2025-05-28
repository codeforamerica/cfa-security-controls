# frozen_string_literal: true

require_relative '../proof'

require 'aws-sdk-configservice'

module CfaSecurityControls
  module Hyperproof
    module Proofs
      module AWS
        # Database encryption evidence for AWS.
        class DatabaseEncryption < Proof
          def name
            'AWS Database Encryption'
          end

          def label
            'Database Encryption'
          end

          # Collect the evidence for this proof.
          #
          # @return [Array<Hash>] The collected evidence.
          def collect
            client = Aws::ConfigService::Client.new
            response = client.select_aggregate_resource_config(
              configuration_aggregator_name: 'aws-controltower-GuardrailsComplianceAggregator',
              expression:
            )

            format(response)
          end

          private

          # AWS Config expression to select the relevant data.
          #
          # @return [String] The AWS Config expression.
          def expression
            <<~SQL
              SELECT #{fields.join(', ')}
              WHERE
                resourceType = 'AWS::RDS::DBInstance'
            SQL
          end

          # Fields to select from the AWS Config service.
          #
          # @return [Array<String>] The fields to select.
          def fields
            %w[accountId resourceId awsRegion availabilityZone resourceName arn
               tags configuration.storageEncrypted configuration.kmsKeyId]
          end

          # Mapping of AWS Config field names to the desired output field names.
          #
          # @return [Hash<String, Symbol>] The mapping of field names.
          def field_map
            {
              'configuration.storageEncrypted' => :storageEncrypted,
              'configuration.kmsKeyId' => :kmsKeyId
            }
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
