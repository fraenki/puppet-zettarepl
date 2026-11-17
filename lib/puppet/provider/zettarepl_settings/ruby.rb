# frozen_string_literal: true

require 'puppet_x/zettarepl/config_file'

Puppet::Type.type(:zettarepl_settings).provide(:ruby) do
  desc 'Manages the global settings in the zettarepl definition file.'

  # Lists the single settings instance.
  #
  # @return [Array<Puppet::Provider>] one provider instance named `zettarepl`
  def self.instances
    [new(name: 'zettarepl')]
  end

  # @return [Hash] all top-level keys except the sections holding named entries
  def config
    PuppetX::Zettarepl::ConfigFile.read.except(*PuppetX::Zettarepl::ConfigFile.sections)
  end

  # Replaces all global settings and keeps the sections untouched.
  #
  # @param value [Hash] the new global settings
  # @return [void]
  def config=(value)
    data = PuppetX::Zettarepl::ConfigFile.read.slice(*PuppetX::Zettarepl::ConfigFile.sections)
    PuppetX::Zettarepl::ConfigFile.write(data.merge(value))
  end
end
