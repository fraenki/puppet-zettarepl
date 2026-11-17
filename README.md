# puppet-zettarepl

#### Table of Contents

1. [Overview](#overview)
1. [Design](#design)
1. [Requirements](#requirements)
1. [Usage](#usage)
    - [Basic usage](#basic-usage)
    - [Global settings](#global-settings)
    - [Periodic snapshot tasks](#periodic-snapshot-tasks)
    - [Transports](#transports)
    - [Replication tasks](#replication-tasks)
    - [Using types directly](#using-types-directly)
    - [Purging unmanaged entries](#purging-unmanaged-entries)
    - [Importing an existing configuration](#importing-an-existing-configuration)
    - [Sensitive data](#sensitive-data)
    - [Managing SSH keys](#managing-ssh-keys)
1. [Reference](#reference)
1. [Development](#development)
    - [Contributing](#contributing)
1. [License](#license)

## Overview

A Puppet module to install and configure [zettarepl](https://github.com/truenas/zettarepl), the ZFS snapshot and replication solution used by TrueNAS, on FreeBSD. It manages the package, the service and the zettarepl definition file `/usr/local/etc/zettarepl.yaml`.

## Design

- The definition file is not rendered from a template. Each periodic snapshot task, replication task and transport is a separate Puppet resource, global settings are managed by a single resource
- Config passthrough — the `config` hash of a resource is written to the definition file as-is, new zettarepl options work without code changes
- Puppet owns every managed entry completely: the `config` hash replaces the whole entry, keys missing from `config` are removed
- Validation delegated to zettarepl — no duplication of the zettarepl schema in Puppet
- The definition file is written atomically with sorted keys
- The service is restarted after configuration changes, because zettarepl reads its definition only on startup

## Requirements

- FreeBSD 14 or 15
- A package repository providing the zettarepl port. The default package name is `py312-zettarepl`; set `zettarepl::package_name` if the package was built for another Python version
- [puppetlabs/stdlib](https://github.com/puppetlabs/puppetlabs-stdlib)

## Usage

### Basic usage

Install zettarepl and start the service with an empty definition:

```puppet
include zettarepl
```

All parameters can be set in Hiera. The following example takes hourly snapshots of a dataset and replicates them to a remote host:

```yaml
zettarepl::settings:
  timezone: 'Europe/Berlin'
zettarepl::periodic_snapshot_tasks:
  data_hourly:
    config:
      dataset: 'tank/data'
      recursive: true
      lifetime: 'P14D'
      naming-schema: 'auto-%Y-%m-%d_%H-%M'
      schedule:
        minute: '0'
zettarepl::transports:
  backup_host:
    config:
      type: 'ssh'
      hostname: 'backup.example.com'
      username: 'root'
      private-key: |
        -----BEGIN OPENSSH PRIVATE KEY-----
        ...
        -----END OPENSSH PRIVATE KEY-----
      host-key: 'ssh-ed25519 AAAA...'
zettarepl::replication_tasks:
  data_offsite:
    config:
      direction: 'push'
      transport: 'backup_host'
      source-dataset:
        - 'tank/data'
      target-dataset: 'backup/data'
      recursive: true
      periodic-snapshot-tasks:
        - 'data_hourly'
      auto: true
      retention-policy: 'source'
```

The keys below `config` are the options of the corresponding section of the zettarepl definition file. Refer to the [zettarepl documentation](https://github.com/truenas/zettarepl) for all available options.

Each entry accepts an optional `ensure` (`present` or `absent`, default `present`). Use `ensure: absent` to remove an entry from the definition file:

```yaml
zettarepl::replication_tasks:
  data_offsite:
    ensure: 'absent'
```

### Global settings

Global settings are all top-level keys of the definition file except the task and transport sections, e.g. `timezone`, `max-parallel-replication-tasks` and `use-removal-dates`. They are managed by the `settings` parameter (type `zettarepl_settings`). The hash replaces all global settings, so settings missing from the hash are removed from the definition file.

```puppet
class { 'zettarepl':
  settings => {
    'max-parallel-replication-tasks' => 2,
    'timezone'                       => 'Europe/Berlin',
  },
}
```

### Periodic snapshot tasks

Periodic snapshot tasks are managed by the `periodic_snapshot_tasks` parameter (type `zettarepl_periodic_snapshot_task`). The hash key is the task name, which is used to bind tasks to replication tasks.

```puppet
class { 'zettarepl':
  periodic_snapshot_tasks => {
    'data_hourly' => {
      'config' => {
        'dataset'       => 'tank/data',
        'recursive'     => true,
        'lifetime'      => 'P14D',
        'naming-schema' => 'auto-%Y-%m-%d_%H-%M',
        'schedule'      => {
          'minute' => '0',
        },
      },
    },
  },
}
```

### Transports

Named transports are managed by the `transports` parameter (type `zettarepl_transport`). A replication task references a named transport by setting its `transport` option to the transport name. Using named transports keeps private keys out of replication tasks, see [Sensitive data](#sensitive-data).

```puppet
class { 'zettarepl':
  transports => {
    'backup_host' => {
      'config' => {
        'type'        => 'ssh',
        'hostname'    => 'backup.example.com',
        'username'    => 'root',
        'private-key' => $private_key,
        'host-key'    => 'ssh-ed25519 AAAA...',
      },
    },
  },
}
```

### Replication tasks

Replication tasks are managed by the `replication_tasks` parameter (type `zettarepl_replication_task`).

```puppet
class { 'zettarepl':
  replication_tasks => {
    'data_offsite' => {
      'config' => {
        'direction'               => 'push',
        'transport'               => 'backup_host',
        'source-dataset'          => ['tank/data'],
        'target-dataset'          => 'backup/data',
        'recursive'               => true,
        'periodic-snapshot-tasks' => ['data_hourly'],
        'auto'                    => true,
        'retention-policy'        => 'source',
      },
    },
  },
}
```

### Using types directly

All types can be used without the class parameters. When the `zettarepl` class is included, changes to these resources also restart the service.

```puppet
zettarepl_periodic_snapshot_task { 'data_hourly':
  ensure => present,
  config => {
    'dataset'       => 'tank/data',
    'recursive'     => true,
    'naming-schema' => 'auto-%Y-%m-%d_%H-%M',
    'schedule'      => {
      'minute' => '0',
    },
  },
}
```

The `zettarepl` class always declares `zettarepl_settings { 'zettarepl': }`, use the `settings` parameter instead of declaring this type.

### Purging unmanaged entries

By default, entries in the definition file that are not managed by Puppet are left untouched. Set `purge` to `true` to remove all periodic snapshot tasks, replication tasks and transports that are not managed by Puppet:

```puppet
class { 'zettarepl':
  purge => true,
}
```

### Importing an existing configuration

All types list the entries of an existing definition file (e.g. one created by a migration from TrueNAS), which helps to convert them to Puppet code or Hiera data:

```shell
puppet resource zettarepl_settings
puppet resource zettarepl_periodic_snapshot_task
puppet resource zettarepl_replication_task
puppet resource zettarepl_transport
```

### Sensitive data

The definition file is created with mode `0600` (parameters `config_owner`, `config_group` and `config_mode`), because SSH transports contain private keys.

The `config` property of `zettarepl_transport` is always treated as sensitive, so its values are redacted from logs and reports. A transport can also be defined inline in the `transport` option of a replication task, but then the private key is not redacted. Use named transports instead.

When using the types directly, any `config` can be marked as sensitive by wrapping it in `Sensitive()`:

```puppet
zettarepl_replication_task { 'data_offsite':
  config => Sensitive({
    'direction' => 'push',
    'transport' => {
      'type'        => 'ssh',
      'private-key' => $private_key,
      # ...
    },
    # ...
  }),
}
```

Private keys should not be stored in plain text in Hiera. Encrypt them, e.g. with [hiera-eyaml](https://github.com/voxpupuli/hiera-eyaml).

### Managing SSH keys

zettarepl connects to the remote host with SSH and needs the following keys:

- **Private key** on the replicating host: zettarepl reads the private key only from the `private-key` option of the transport (RSA, ECDSA or Ed25519). Existing key files are not read, so the key must be passed to the transport `config`, e.g. from encrypted Hiera data.
- **Host key** of the remote host: the `host-key` option of the transport contains the public host key of the remote host in the form `<type> <base64>`, e.g. the first two fields of `/etc/ssh/ssh_host_ed25519_key.pub` on the remote host. The `known_hosts` file of the user is not used.
- **Authorized key** on the remote host: the public key matching `private-key` must be added to the `authorized_keys` file of the remote user.

The authorized key can be managed with the `ssh_authorized_key` type from [puppetlabs/sshkeys_core](https://github.com/puppetlabs/puppetlabs-sshkeys_core), which is shipped with the FreeBSD `openvox-agent8` package:

```puppet
ssh_authorized_key { 'zettarepl@source.example.com':
  ensure => present,
  user   => 'root',
  type   => 'ssh-ed25519',
  key    => 'AAAA...',
}
```

The FreeBSD sshd does not permit root logins by default (`PermitRootLogin no`). When replicating as root, permit key-based root logins on the remote host, e.g. with [saz/ssh](https://github.com/saz/puppet-ssh):

```puppet
class { 'ssh::server':
  options => {
    'PermitRootLogin' => 'prohibit-password',
  },
}
```

Alternatively use a non-root user (`username` option of the transport) and set the transport option `sudo` to `true`. zettarepl then prefixes all commands on the remote host with `sudo`, so the remote user needs passwordless sudo permissions for them.

The `ssh_keygen` type from [puppet/ssh_keygen](https://github.com/voxpupuli/puppet-ssh_keygen) generates key files on the managed node. Since zettarepl does not read key files, such a key cannot be used without passing its content to the transport `config`.

## Reference

Classes, types and parameters are documented in [REFERENCE.md](REFERENCE.md).

All default values can be found in the `data/` directory.

## Development

### Contributing

Please use the GitHub issues functionality to report any bugs or requests for new features. Feel free to fork and submit pull requests for potential contributions.

## License

BSD-2-Clause
