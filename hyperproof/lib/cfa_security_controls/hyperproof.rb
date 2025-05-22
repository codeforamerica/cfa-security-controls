# frozen_string_literal: true

require_relative 'hyperproof/entities/label'
require_relative 'hyperproof/entities/proof'
require_relative 'hyperproof/proofs'

module CfaSecurityControls
  # Top level module for our gem.
  module Hyperproof
    # Collect all proofs without writing them to Hyperproof.
    def self.collect
      Proofs.proofs.map do |collector|
        r = collector.new.collect
        pp(r)
      end
    end

    # Collect and upload all proofs to Hyperproof.
    def self.run
      Dir.mktmpdir do |dir|
        writer = Writer.new(dir)
        Proofs.proofs.map do |klass|
          proof = klass.new
          filename = proof.write(writer)

          label = Entities::Label.new(proof.label)
          label.create unless label.exists?
          entity = Entities::Proof.new(File.basename(filename), label:)
          entity.create(filename)
        end
      end
    end
  end
end
