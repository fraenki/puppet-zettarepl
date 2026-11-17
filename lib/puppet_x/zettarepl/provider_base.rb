# frozen_string_literal: true

require 'puppet_x/zettarepl'
require 'puppet_x/zettarepl/config_file'

# Shared provider logic for named entries in one section of the zettarepl
# definition file. A provider includes this module and defines
# `self.section`.
module PuppetX::Zettarepl::ProviderBase
  # Extends the including provider with {ClassMethods}.
  #
  # @param base [Class] the including provider class
  # @return [void]
  def self.included(base)
    base.extend(ClassMethods)
  end

  # Class methods for listing and prefetching entries.
  module ClassMethods
    # Lists all entries of the provider's section.
    #
    # @return [Array<Puppet::Provider>] one provider instance per entry
    def instances
      entries = PuppetX::Zettarepl::ConfigFile.read[section] || {}
      entries.map do |entry_name, entry_config|
        new(name: entry_name.to_s, ensure: :present, config: entry_config)
      end
    end

    # Assigns the provider instances of existing entries to the matching
    # resources.
    #
    # @param resources [Hash{String => Puppet::Type}] the resources by name
    # @return [void]
    def prefetch(resources)
      instances.each do |provider|
        resource = resources[provider.name]
        resource.provider = provider if resource
      end
    end
  end

  # @return [Boolean] whether the entry exists
  def exists?
    @property_hash[:ensure] == :present
  end

  # Adds the entry to the definition file.
  #
  # @return [void]
  # @raise [Puppet::Error] if the resource has no config
  def create
    raise Puppet::Error, "#{resource.ref}: config is required when ensure is present" if resource[:config].nil?

    write_entry(resource[:config])
    @property_hash[:ensure] = :present
    @property_hash[:config] = resource[:config]
  end

  # Removes the entry from the definition file.
  #
  # @return [void]
  def destroy
    write_entry(nil)
    @property_hash.clear
  end

  # @return [Hash] the current definition of the entry
  def config
    @property_hash[:config]
  end

  # Replaces the whole entry in the definition file.
  #
  # @param value [Hash] the new definition of the entry
  # @return [void]
  def config=(value)
    write_entry(value)
    @property_hash[:config] = value
  end

  private

  # Re-reads the file, replaces this entry (or removes it if config is nil)
  # and writes the file back. Keys are matched as strings because YAML may
  # load numeric entry names as integers. Empty sections are removed.
  #
  # @param entry_config [Hash, nil] the new definition of the entry
  # @return [void]
  def write_entry(entry_config)
    section = self.class.section
    data = PuppetX::Zettarepl::ConfigFile.read
    entries = (data[section] || {}).reject { |entry_name, _| entry_name.to_s == name }
    entries[name] = entry_config unless entry_config.nil?
    if entries.empty?
      data.delete(section)
    else
      data[section] = entries
    end
    PuppetX::Zettarepl::ConfigFile.write(data)
  end
end
