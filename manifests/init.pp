# @summary Install and configure zettarepl
#
# This class installs the zettarepl package, manages the zettarepl service and
# creates zettarepl_* resources for the global settings, periodic snapshot
# tasks, replication tasks and transports in the zettarepl definition file.
#
# @param config_group
#   The group owning the zettarepl configuration file.
#
# @param config_mode
#   The file mode of the zettarepl configuration file.
#
# @param config_owner
#   The user owning the zettarepl configuration file.
#
# @param package_ensure
#   Overwrite the package `ensure` parameter.
#
# @param package_manage
#   Set to `false` to disable package management.
#
# @param package_name
#   The name of the zettarepl package.
#
# @param periodic_snapshot_tasks
#   Hash of periodic snapshot tasks to manage.
#   Each key is the task name. Each value is a hash with:
#     - ensure [String] 'present' or 'absent' (default: 'present')
#     - config [Hash] Task definition passed to zettarepl_periodic_snapshot_task.
#
# @param purge
#   Set to `true` to remove all periodic snapshot tasks, replication tasks
#   and transports that are not managed by Puppet.
#
# @param replication_tasks
#   Hash of replication tasks to manage.
#   Each key is the task name. Each value is a hash with:
#     - ensure [String] 'present' or 'absent' (default: 'present')
#     - config [Hash] Task definition passed to zettarepl_replication_task.
#
# @param service_enable
#   Whether the zettarepl service should be enabled at boot.
#
# @param service_ensure
#   Whether the zettarepl service should be running.
#
# @param service_manage
#   Set to `false` to disable service management.
#
# @param service_name
#   The name of the zettarepl service.
#
# @param settings
#   Hash of global zettarepl settings (all top-level keys except the task and
#   transport sections), e.g. `timezone`. Passed to zettarepl_settings.
#
# @param transports
#   Hash of named transports to manage.
#   Each key is the transport name. Each value is a hash with:
#     - ensure [String] 'present' or 'absent' (default: 'present')
#     - config [Hash] Transport definition passed to zettarepl_transport.
#
# @example Hourly snapshots of a dataset replicated to a remote host
#   class { 'zettarepl':
#     settings                => {
#       'timezone' => 'Europe/Berlin',
#     },
#     periodic_snapshot_tasks => {
#       'data_hourly' => {
#         'config' => {
#           'dataset'       => 'tank/data',
#           'recursive'     => true,
#           'lifetime'      => 'P14D',
#           'naming-schema' => 'auto-%Y-%m-%d_%H-%M',
#           'schedule'      => {
#             'minute' => '0',
#           },
#         },
#       },
#     },
#     transports              => {
#       'backup_host' => {
#         'config' => {
#           'type'        => 'ssh',
#           'hostname'    => 'backup.example.com',
#           'username'    => 'root',
#           'private-key' => $private_key,
#           'host-key'    => 'ssh-ed25519 AAAA...',
#         },
#       },
#     },
#     replication_tasks       => {
#       'data_offsite' => {
#         'config' => {
#           'direction'               => 'push',
#           'transport'               => 'backup_host',
#           'source-dataset'          => ['tank/data'],
#           'target-dataset'          => 'backup/data',
#           'recursive'               => true,
#           'periodic-snapshot-tasks' => ['data_hourly'],
#           'auto'                    => true,
#           'retention-policy'        => 'source',
#         },
#       },
#     },
#   }
#
class zettarepl (
  String[1] $config_group,
  Stdlib::Filemode $config_mode,
  String[1] $config_owner,
  String[1] $package_ensure,
  Boolean $package_manage,
  String[1] $package_name,
  Hash $periodic_snapshot_tasks,
  Boolean $purge,
  Hash $replication_tasks,
  Boolean $service_enable,
  Enum['running','stopped'] $service_ensure,
  Boolean $service_manage,
  String[1] $service_name,
  Hash $settings,
  Hash $transports,
) {
  contain zettarepl::install
  contain zettarepl::config
  contain zettarepl::service

  Class['zettarepl::install'] -> Class['zettarepl::config'] ~> Class['zettarepl::service']

  # Restart the service after changes to any zettarepl_* resource, including
  # resources declared outside of this class.
  Class['zettarepl::install']
  -> Zettarepl_periodic_snapshot_task <| |>
  ~> Class['zettarepl::service']

  Class['zettarepl::install']
  -> Zettarepl_replication_task <| |>
  ~> Class['zettarepl::service']

  Class['zettarepl::install']
  -> Zettarepl_settings <| |>
  ~> Class['zettarepl::service']

  Class['zettarepl::install']
  -> Zettarepl_transport <| |>
  ~> Class['zettarepl::service']
}
