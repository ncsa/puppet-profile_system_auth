# @summary Configure system auth
#
# @param authselect_profile
#   String of authselect profile
#   Valid only for >= RHEL8
#
# @param enable_mkhomedir
#   Boolean to enable mkhomedir on user login
#
# @param oddjobd_mkhomedir_conf
#   String of file content for /etc/oddjobd.conf.d/oddjobd-mkhomedir.conf
#
# @param removed_pkgs
#   Optional array of Strings of package names to remove
#
# @param required_pkgs
#   Array of strings of package names to install
#
# @param use_authconfig
#   Boolean to use optional authconfig instead of default authselect
#
# @example
#   include profile_system_auth::config
class profile_system_auth::config (
  String             $authselect_profile,
  Boolean            $enable_mkhomedir,
  String             $oddjobd_mkhomedir_conf,
  $removed_pkgs,
  Array[ String[1] ] $required_pkgs,
  Boolean            $use_authconfig,
) {

  $file_defaults = {
    owner  => root,
    group  => root,
    ensure => file,
    mode   => '0644',
  }

  if ($removed_pkgs)
  {
    ensure_packages( $removed_pkgs, {'ensure' => 'absent', })
  }

  ensure_packages( $required_pkgs )

  if ( $use_authconfig )
  {
    exec { 'authconfig_enablesssdauth':
      path    => '/sbin/:/bin/:/usr/bin/:/usr/sbin/',
      onlyif  => 'test `grep -i "USESSSD" /etc/sysconfig/authconfig | grep -i "\=yes" | wc -l` -lt 2',
      command => 'authconfig --enablesssd --enablesssdauth --update',
    }
  }
  else
  {
    exec { "authselect_select_${authselect_profile}":
      path    => '/sbin/:/bin/:/usr/bin/:/usr/sbin/',
      onlyif  => "test `authselect current | grep -i profile | grep -i ${authselect_profile} | wc -l` -lt 1",
      command => "authselect select ${authselect_profile} --force",
    }
  }

  # ENABLE MKHOMEDIR (create homedir on first login)
  if $enable_mkhomedir
  {
    service { 'oddjobd':
      require => [
        Package[$required_pkgs],
      ],
    }
    file {
      '/etc/oddjobd.conf.d/oddjobd-mkhomedir.conf':
        content => $oddjobd_mkhomedir_conf,
        notify  => Service['oddjobd'],
      ;
      default: * => $file_defaults
      ;
    }
    if ( $use_authconfig )
    {
      exec { 'authconfig_enable_mkhomedir':
        path    => '/sbin/:/bin/:/usr/bin/:/usr/sbin/',
        onlyif  => 'test `grep -i "USEMKHOMEDIR" /etc/sysconfig/authconfig | grep -i "\=yes" | wc -l` -lt 1',
        command => 'authconfig --enablemkhomedir --update',
      }
    }
    else
    {
      exec { 'authselect_enable_mkhomedir':
        path    => '/sbin/:/bin/:/usr/bin/:/usr/sbin/',
        onlyif  => 'test `authselect current | grep -i "with-mkhomedir" | wc -l` -lt 1',
        command => 'authselect enable-feature with-mkhomedir',
      }
    }

  }
  else
  {
    if ( $use_authconfig )
    {
      exec { 'authconfig_disable_mkhomedir':
        path    => '/sbin/:/bin/:/usr/bin/:/usr/sbin/',
        onlyif  => 'test `grep -i "USEMKHOMEDIR" /etc/sysconfig/authconfig | grep -i "\=yes" | wc -l` -gt 0',
        command => 'authconfig --disablemkhomedir --update',
      }
    }
    else
    {
      exec { 'authselect_disable_mkhomedir':
        path    => '/sbin/:/bin/:/usr/bin/:/usr/sbin/',
        onlyif  => 'test `authselect current | grep -i "with-mkhomedir" | wc -l` -gt 0',
        command => 'authselect disable-feature with-mkhomedir',
      }
    }
  }

}
