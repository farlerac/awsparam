# awsparam/init.pp
#
# Main awsparam class
#
# @example
#   include awsparam
class awsparam {

  package { 'awscli':
    ensure => present,
  }

}
