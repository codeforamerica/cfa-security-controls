# frozen_string_literal: true

require_relative 'hyperproof/config'
require_relative 'hyperproof/entities/label'
require_relative 'hyperproof/entities/proof'
require_relative 'hyperproof/proofs'

module CfaSecurityControls
  # Top level module for our gem.
  module Hyperproof
    @mutex = Mutex.new

    # Set or load the system configuration.
    #
    # If no configuration is explicitly set, it will be loaded from the
    # environment.
    #
    # @param config [Config] Configuration to set for the system.
    def self.config(config = nil)
      @mutex.synchronize do
        if config
          @config = config
        else
          @config ||= Config.from_environment
        end
      end
    end

    # Collect and upload all proofs to Hyperproof.
    def self.run
      Dir.mktmpdir do |dir|
        config.logger.info("Writing proofs to #{dir}")
        writer = Writer.new(dir)
        Proofs.proofs.map do |klass|
          proof = klass.new
          filename = collect_proof(proof, writer)
          Entities::Proof.new(File.basename(filename), label: proof_label(proof))
                         .create(filename)
        end
      end
    end

    # Collect evidence for a specific proof.
    #
    # @param proof [Proofs::Proof] The proof to collect evidence for.
    # @param writer [Writer] The writer to use for formatting the proof.
    # @return [String] The filename where the proof was written.
    private_class_method def self.collect_proof(proof, writer)
      config.logger.debug("Collecting proof for #{proof.name} (#{proof.label})")
      proof.write(writer)
    end

    # Get the label for a proof.
    #
    # @param proof [Proofs::Proof] The proof to get the label for.
    # @return [Entities::Label] The label entity for the proof.
    private_class_method def self.proof_label(proof)
      label = Entities::Label.new(proof.label)
      label.create unless label.exists?
      label
    end
  end
end
