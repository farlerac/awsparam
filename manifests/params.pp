# Class: awsparam::params
#
# Manages parameters for the awsparams module
#
# @example
#   include awsparam::params
class awsparam::params {

  case $::osfamily {
    'RedHat': {
      if $::operatingsystemmajrelease != '7' {
        fail("Unsupported RedHat family version: ${::operatingsystemmajrelease}")
      }

      $package = 'awscli'

    }
    default: {
      fail("Unsupported osfamily: ${::osfamily}")
    }
  }

}
