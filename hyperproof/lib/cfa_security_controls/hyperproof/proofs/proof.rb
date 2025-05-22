# frozen_string_literal: true

module CfaSecurityControls
  module Hyperproof
    module Proofs
      # Base class for all proofs.
      class Proof
        # Label that this proof is associated with.
        #
        # @return [String] Name of the label.
        def label
          raise NotImplementedError, 'Subclasses must implement a label method'
        end

        # Name for the proof.
        #
        # The name should not include a file extension. This will be added by
        # the writer based on the format.
        #
        # @return [String] Name of the proof.
        def name
          raise NotImplementedError, 'Subclasses must implement a name method'
        end

        # Write the proof to a file.
        #
        # @param writer [Writer] The writer to use for writing the proof.
        # @return [String] The absolute path to the written file.
        def write(writer)
          writer.write(name, collect)
        end
      end
    end
  end
end
