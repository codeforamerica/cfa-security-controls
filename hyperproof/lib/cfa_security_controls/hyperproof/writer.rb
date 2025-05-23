# frozen_string_literal: true

require 'csv'

module CfaSecurityControls
  module Hyperproof
    # Write evidence for proof to a file.
    class Writer
      # Initialize a new writer.
      #
      # @param path [String] The directory to write the file to.
      def initialize(path = Dir.tmpdir)
        @path = path
      end

      # Write the data to a file.
      #
      # @param filename [String] The name of the file to write to, without
      #   extension.
      # @param data [Array<Hash>] The data to write to the file.
      # @return [String] The absolute path to the file.
      def write(filename, data)
        filename += '.csv' unless filename.end_with?('.csv')
        filename = File.join(@path, filename)

        CSV.open(filename, 'w') do |csv|
          csv << data.first.keys if data.any?
          data.each { |row| csv << row.values }
        end

        File.absolute_path(filename)
      end
    end
  end
end
