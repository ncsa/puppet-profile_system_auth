# @summary Configure system auth
#
# Configures system authconfig, enable mkhomedir, etc
#
# @example
#   include profile_system_auth::config
class profile_system_auth::config (
  Boolean            $enablemkhomedir,
  String             $oddjobd_mkhomedir_conf,
  Array[ String[1] ] $required_pkgs,     # DEFAULT SET VIA MODULE DATA
) {

  $file_defaults = {
    owner  => root,
    group  => root,
    ensure => file,
    mode   => '0644',
  }

  ensure_packages( $required_pkgs )

  # ENABLE MKHOMEDIR (create homedir on first login)
  if $enablemkhomedir
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
    exec { 'authconfig_enablemkhomedir':
      path    => '/sbin/:/bin/:/usr/bin/:/usr/sbin/',
      onlyif  => 'test `grep -i "USEMKHOMEDIR" /etc/sysconfig/authconfig | grep -i "\=yes" | wc -l` -lt 1',
      command => 'authconfig --enablemkhomedir --update',
    }

  }
  else
  {
    exec { 'authconfig_disablemkhomedir':
      path    => '/sbin/:/bin/:/usr/bin/:/usr/sbin/',
      onlyif  => 'test `grep -i "USEMKHOMEDIR" /etc/sysconfig/authconfig | grep -i "\=yes" | wc -l` -gt 0',
      command => 'authconfig --disablemkhomedir --update',
    }
  }

  exec { 'authconfig_enablesssdauth':
    path    => '/sbin/:/bin/:/usr/bin/:/usr/sbin/',
    onlyif  => 'test `grep -i "USESSSD" /etc/sysconfig/authconfig | grep -i "\=yes" | wc -l` -lt 2',
    command => 'authconfig --enablesssd --enablesssdauth --update',
  }

}
