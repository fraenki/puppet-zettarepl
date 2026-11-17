# frozen_string_literal: true

require 'yaml'
require 'puppet/util'
require_relative '../zettarepl'

# Reads and writes the zettarepl definition file.
module PuppetX::Zettarepl::ConfigFile
  # @return [String] the absolute path of the zettarepl definition file
  def self.path
    '/usr/local/etc/zettarepl.yaml'
  end

  # @return [Array<String>] the top-level keys holding named entries; all
  #   other top-level keys are global settings
  def self.sections
    ['periodic-snapshot-tasks', 'replication-tasks', 'transports']
  end

  # Reads and parses the definition file.
  #
  # @return [Hash] the parsed definition, or an empty hash if the file is
  #   missing or empty
  # @raise [Puppet::Error] if the file is not valid YAML or its content is
  #   not a hash
  def self.read
    return {} unless File.exist?(path)

    begin
      data = YAML.safe_load_file(path, aliases: true)
    rescue Psych::Exception => e
      raise Puppet::Error, "Unable to parse #{path}: #{e.message}"
    end
    return {} if data.nil?
    raise Puppet::Error, "Unable to parse #{path}: content is not a hash" unless data.is_a?(Hash)

    data
  end

  # Writes the definition file atomically. A new file is created with mode
  # 0600, an existing file keeps its mode and owner.
  #
  # @param data [Hash] the complete definition
  # @return [void]
  def self.write(data)
    Puppet::Util.replace_file(path, '0600') do |file|
      file.write(YAML.dump(deep_sort(data)))
    end
  end

  # Sorts hash keys recursively (compared as strings, so numeric task names
  # do not break the sort) to produce a stable file layout.
  #
  # @param value [Object] the value to sort
  # @return [Object] the value with all nested hash keys sorted
  def self.deep_sort(value)
    case value
    when Hash
      value.sort_by { |key, _| key.to_s }.to_h.transform_values { |item| deep_sort(item) }
    when Array
      value.map { |item| deep_sort(item) }
    else
      value
    end
  end
end
