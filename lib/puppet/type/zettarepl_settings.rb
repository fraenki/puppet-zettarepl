# frozen_string_literal: true

require_relative '../../puppet_x/zettarepl/config_file'

Puppet::Type.newtype(:zettarepl_settings) do
  desc <<-DOC
    @summary Manages the global settings in the zettarepl definition file.

    Global settings are all top-level keys of /usr/local/etc/zettarepl.yaml
    except the `periodic-snapshot-tasks`, `replication-tasks` and `transports`
    sections. The `config` hash replaces all global settings, so keys missing
    from `config` are removed. Only one instance of this type should be
    declared. Validation is performed by zettarepl, not by Puppet.

    @example Set the timezone and limit parallel replication tasks
      zettarepl_settings { 'zettarepl':
        config => {
          'max-parallel-replication-tasks' => 2,
          'timezone'                       => 'Europe/Berlin',
        },
      }
  DOC

  newparam(:name, namevar: true) do
    desc 'An arbitrary name for this resource, usually `zettarepl`.'

    validate do |value|
      raise ArgumentError, 'name must be a non-empty string' unless value.is_a?(String) && !value.empty?
    end
  end

  newproperty(:config) do
    desc <<-DOC
      A hash with all global settings, using the top-level keys of the
      zettarepl definition file (e.g. `timezone`,
      `max-parallel-replication-tasks`, `use-removal-dates`).
    DOC

    validate do |value|
      raise ArgumentError, 'config must be a Hash' unless value.is_a?(Hash)

      sections = value.keys & PuppetX::Zettarepl::ConfigFile.sections
      raise ArgumentError, "config must not contain the sections #{sections.join(', ')}" unless sections.empty?
    end
  end
end
