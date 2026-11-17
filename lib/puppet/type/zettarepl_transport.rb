# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
Puppet::Type.newtype(:zettarepl_transport) do
  desc <<-DOC
    @summary Manages a named transport in the zettarepl definition file.

    The transport is stored in the `transports` section of
    /usr/local/etc/zettarepl.yaml and can be referenced by name in the
    `transport` key of replication tasks. The `config` hash is written as-is
    and replaces the whole transport definition. Validation is performed by
    zettarepl, not by Puppet.

    The `config` property is always treated as sensitive, because SSH
    transports contain a private key.

    @example Define an SSH transport
      zettarepl_transport { 'backup_host':
        ensure => present,
        config => {
          'type'        => 'ssh',
          'hostname'    => 'backup.example.com',
          'username'    => 'root',
          'private-key' => $private_key,
          'host-key'    => 'ssh-ed25519 AAAA...',
        },
      }
  DOC

  ensurable do
    desc 'Whether the transport should be present or absent.'

    defaultvalues
    defaultto :present
  end

  newparam(:name, namevar: true) do
    desc 'The name of the transport.'

    validate do |value|
      raise ArgumentError, 'name must be a non-empty string' unless value.is_a?(String) && !value.empty?
    end
  end

  newproperty(:config) do
    desc <<-DOC
      A hash with the complete transport definition, using the keys of the
      zettarepl `transports` section (e.g. `type`, `hostname`, `username`,
      `private-key`, `host-key`).
    DOC

    sensitive true

    validate do |value|
      raise ArgumentError, 'config must be a Hash' unless value.is_a?(Hash)
    end
  end
end
# rubocop:enable Metrics/BlockLength
