# frozen_string_literal: true

require 'concurrent-ruby'

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
      collect_proofs do |proof, writer|
        create_proof(proof, writer)
      end
    end

    # Collect all proofs, but don't upload them to Hyperproof.
    def self.collect
      collect_proofs do |proof, writer|
        filename = collect_proof(proof, writer)
        config.logger.debug("Collected proof for #{proof.name} to #{filename}")
        [proof.name, filename]
      rescue StandardError => e
        handle_exception(proof, e)
      end
    end

    # Create the proof in Hyperproof.
    #
    # @param proof [Proofs::Proof] The proof to create.
    # @param writer [Writer] The writer to use for formatting the proof.
    # @return [Array] A promise response containing the proof name and its ID.
    private_class_method def self.create_proof(proof, writer)
      filename = collect_proof(proof, writer)
      entity = Entities::Proof.new(File.basename(filename), label: proof_label(proof))
      config.logger.debug("Syncing proof for #{proof.name} (#{proof.label}) at #{filename}")
      entity.create(filename)
      [proof.name, entity.id]
    rescue StandardError => e
      handle_exception(proof, e)
    end

    # Handle exceptions that occur during proof collection.
    #
    # @param proof [Proofs::Proof] The proof that was being processed.
    # @param error [StandardError] The error that occurred.
    # @return [Array] Valid promise repose representing a failure.
    private_class_method def self.handle_exception(proof, error)
      config.logger.error("An error occurred: #{error.message}")
      [proof.name, false]
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

    # Collect all proofs and yield to the caller for processing.
    private_class_method def self.collect_proofs(&)
      Dir.mktmpdir do |dir|
        config.logger.info("Writing proofs to #{dir}")

        writer = Writer.new(dir)
        futures = Proofs.proofs.map do |klass|
          Concurrent::Promises.future(executor: config.thread_pool) do
            yield klass.new, writer
          end.run
        end

        # Wait for all futures to complete and collect results.
        Concurrent::Promises.zip(*futures).value!.to_h
      end
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
