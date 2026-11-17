# @summary Manage the zettarepl service
# @api private
class zettarepl::service {
  assert_private()

  if $zettarepl::service_manage {
    service { $zettarepl::service_name:
      ensure => $zettarepl::service_ensure,
      enable => $zettarepl::service_enable,
    }
  }
}
