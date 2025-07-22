# frozen_string_literal: true

require_relative 'base'

module CfaSecurityControls
  module Hyperproof
    module Proofs
      module AWS
        # EC2 volume encryption evidence for AWS.
        class VolumeEncryption < Base
          def name
            'AWS Volume Encryption'
          end

          def label
            'Disk Encryption'
          end

          private

          def resource_type
            'AWS::EC2::Volume'
          end

          def fields
            super + %w[configuration.encrypted configuration.kmsKeyId]
          end

          def field_map
            {
              'configuration.encrypted' => :encrypted,
              'configuration.kmsKeyId' => :kmsKeyId
            }
          end
        end
      end
    end
  end
end
