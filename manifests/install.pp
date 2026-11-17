# @summary Install the zettarepl package
# @api private
class zettarepl::install {
  assert_private()

  if $zettarepl::package_manage {
    package { $zettarepl::package_name:
      ensure => $zettarepl::package_ensure,
    }
  }
}
