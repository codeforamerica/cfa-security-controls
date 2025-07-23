# frozen_string_literal: true

require_relative 'base'

module CfaSecurityControls
  module Hyperproof
    module Proofs
      module AWS
        # EFS encryption evidence for AWS.
        class EFSEncryption < Base
          def name
            'EFS Encryption'
          end

          def label
            'Disk Encryption'
          end

          private

          def resource_type
            'AWS::EFS::FileSystem'
          end

          def fields
            super + %w[configuration.Encrypted configuration.KmsKeyId]
          end

          def field_map
            {
              'configuration.Encrypted' => :encrypted,
              'configuration.KmsKeyId' => :kmsKeyId
            }
          end
        end
      end
    end
  end
end
