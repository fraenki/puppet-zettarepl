# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
Puppet::Type.newtype(:zettarepl_replication_task) do
  desc <<-DOC
    @summary Manages a replication task in the zettarepl definition file.

    The task is stored in the `replication-tasks` section of
    /usr/local/etc/zettarepl.yaml. The `config` hash is written as-is and
    replaces the whole task definition. Validation is performed by zettarepl,
    not by Puppet.

    @example Push snapshots to a remote host using a named transport
      zettarepl_replication_task { 'data_offsite':
        ensure => present,
        config => {
          'direction'               => 'push',
          'transport'               => 'backup_host',
          'source-dataset'          => ['tank/data'],
          'target-dataset'          => 'backup/data',
          'recursive'               => true,
          'periodic-snapshot-tasks' => ['data_hourly'],
          'auto'                    => true,
          'retention-policy'        => 'source',
        },
      }
  DOC

  ensurable do
    desc 'Whether the replication task should be present or absent.'

    defaultvalues
    defaultto :present
  end

  newparam(:name, namevar: true) do
    desc 'The name of the replication task.'

    validate do |value|
      raise ArgumentError, 'name must be a non-empty string' unless value.is_a?(String) && !value.empty?
    end
  end

  newproperty(:config) do
    desc <<-DOC
      A hash with the complete task definition, using the keys of the
      zettarepl `replication-tasks` section (e.g. `direction`, `transport`,
      `source-dataset`, `target-dataset`, `retention-policy`).
    DOC

    validate do |value|
      raise ArgumentError, 'config must be a Hash' unless value.is_a?(Hash)
    end
  end
end
# rubocop:enable Metrics/BlockLength
