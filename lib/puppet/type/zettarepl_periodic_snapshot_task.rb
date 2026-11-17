# frozen_string_literal: true

Puppet::Type.newtype(:zettarepl_periodic_snapshot_task) do
  desc <<-DOC
    @summary Manages a periodic snapshot task in the zettarepl definition file.

    The task is stored in the `periodic-snapshot-tasks` section of
    /usr/local/etc/zettarepl.yaml. The `config` hash is written as-is and
    replaces the whole task definition. Validation is performed by zettarepl,
    not by Puppet.

    @example Take hourly snapshots of a dataset
      zettarepl_periodic_snapshot_task { 'data_hourly':
        ensure => present,
        config => {
          'dataset'       => 'tank/data',
          'recursive'     => true,
          'lifetime'      => 'P14D',
          'naming-schema' => 'auto-%Y-%m-%d_%H-%M',
          'schedule'      => {
            'minute' => '0',
          },
        },
      }
  DOC

  ensurable do
    desc 'Whether the periodic snapshot task should be present or absent.'

    defaultvalues
    defaultto :present
  end

  newparam(:name, namevar: true) do
    desc 'The name of the periodic snapshot task.'

    validate do |value|
      raise ArgumentError, 'name must be a non-empty string' unless value.is_a?(String) && !value.empty?
    end
  end

  newproperty(:config) do
    desc <<-DOC
      A hash with the complete task definition, using the keys of the
      zettarepl `periodic-snapshot-tasks` section (e.g. `dataset`,
      `recursive`, `naming-schema`, `schedule`).
    DOC

    validate do |value|
      raise ArgumentError, 'config must be a Hash' unless value.is_a?(Hash)
    end
  end
end
