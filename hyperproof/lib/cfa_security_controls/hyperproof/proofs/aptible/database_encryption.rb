# frozen_string_literal: true

require_relative '../proof'
require_relative '../../clients/aptible'

module CfaSecurityControls
  module Hyperproof
    module Proofs
      module Aptible
        # Database encryption evidence for Aptible.
        class DatabaseEncryption < Proof
          def name
            'Aptible Database Encryption'
          end

          def label
            'Database Encryption'
          end

          # Collect the evidence for this proof.
          #
          # @return [Array<Hash>] The collected evidence.
          def collect
            client = Clients::Aptible.new
            client.databases.map do |db|
              disk = db.disk
              {
                id: db.id,
                name: db.handle,
                type: db.type,
                status: db.status,
                filesystem: disk.filesystem,
                key_bytes: disk.key_bytes
              }
            end
          end

          private

          def fields
            %w[accountId resourceId awsRegion availabilityZone resourceName arn
               tags configuration.storageEncrypted configuration.kmsKeyId]
          end

          def field_map
            {
              'configuration.storageEncrypted' => 'storageEncrypted',
              'configuration.kmsKeyId' => 'kmsKeyId'
            }
          end

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
