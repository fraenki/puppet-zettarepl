# @summary Manage the zettarepl configuration
# @api private
class zettarepl::config {
  assert_private()

  # The zettarepl_* providers write to the same fixed path.
  $config_file = '/usr/local/etc/zettarepl.yaml'

  # Create an empty definition if the file does not exist. Existing content is
  # managed by the zettarepl_* resources and never replaced, ownership and
  # permissions are always enforced.
  file { $config_file:
    ensure  => file,
    owner   => $zettarepl::config_owner,
    group   => $zettarepl::config_group,
    mode    => $zettarepl::config_mode,
    content => "--- {}\n",
    replace => false,
  }

  File[$config_file] -> Zettarepl_periodic_snapshot_task <| |>
  File[$config_file] -> Zettarepl_replication_task <| |>
  File[$config_file] -> Zettarepl_settings <| |>
  File[$config_file] -> Zettarepl_transport <| |>

  zettarepl_settings { 'zettarepl':
    config => $zettarepl::settings,
  }

  # Manage periodic snapshot tasks
  $zettarepl::periodic_snapshot_tasks.each |String $task_name, Hash $task_options| {
    zettarepl_periodic_snapshot_task { $task_name:
      ensure => pick($task_options['ensure'], 'present'),
      config => $task_options['config'],
    }
  }

  # Manage replication tasks
  $zettarepl::replication_tasks.each |String $task_name, Hash $task_options| {
    zettarepl_replication_task { $task_name:
      ensure => pick($task_options['ensure'], 'present'),
      config => $task_options['config'],
    }
  }

  # Manage transports
  $zettarepl::transports.each |String $transport_name, Hash $transport_options| {
    zettarepl_transport { $transport_name:
      ensure => pick($transport_options['ensure'], 'present'),
      config => $transport_options['config'],
    }
  }

  # The purged resources inherit `notify` and restart the service on removal.
  if $zettarepl::purge {
    resources { ['zettarepl_periodic_snapshot_task', 'zettarepl_replication_task', 'zettarepl_transport']:
      purge  => true,
      notify => Class['zettarepl::service'],
    }
  }
}
