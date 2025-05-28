# frozen_string_literal: true

require_relative 'proofs/aptible'
require_relative 'proofs/aws'

module CfaSecurityControls
  module Hyperproof
    # Proofs that can be collected and sent to Hyperproof.
    module Proofs
      # Find all proof classes.
      #
      # @return [Array<Class>] An array of proof classes.
      def self.proofs
        proofs_for_namespace(self)
      end

      # Find all proof classes in a given namespace.
      #
      # This method will recursively search through the constants of the given
      # namespace and collect all classes that have a `collect` method defined.
      #
      # @param namespace [Module] The namespace to search for proof classes.
      # @return [Array<Class>] An array of proof classes found in the namespace.
      private_class_method def self.proofs_for_namespace(namespace)
        namespace.constants.each_with_object([]) do |const_name, collectors|
          const = namespace.const_get(const_name)
          if const.is_a?(Class) && const.method_defined?(:collect)
            collectors << const
          else
            collectors.concat(proofs_for_namespace(const))
          end
        end
      end
    end
  end
end
