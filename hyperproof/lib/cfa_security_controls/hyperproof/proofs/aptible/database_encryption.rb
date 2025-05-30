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
        end
      end
    end
  end
end
