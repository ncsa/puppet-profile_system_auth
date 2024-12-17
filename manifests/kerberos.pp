# profile_system_auth::kerberos
#
# @summary Basic kerberos client setup, with optional host principal management
#
# @param ad_computers_ou
#   Optional String of AD OU where computer objects should be created
#
# @param ad_createhostkeytab
#   Optional String of base64 encoding of AD krb5 createhost keytab file
#
# @param ad_createhostuser
#   Optional String of user with permissions to create host in AD
#
# @param ad_domain
#   Optional String of the Active Directory domain that the computer should join
#
# @param cfg_file_settings
#   Hash of file resource parameters for various config files
#
# @param createhostkeytab
#   Optional String of base64 encoding of krb5 createhost keytab file
#
# @param createhostuser
#   Optional String of kerberos principal username to be used for kerberos createhost
#
# @param crons
#   Hash of cron resource parameters for any CRON entries related to kerberos keytab cleanup
#
# @param domain
#   Optional String of the Kerberos domain that the computer should join
#
# @param enable
#   Used to enable or disable kerberos
#
# @param files_remove_setuid
#   Hash of file resource paramters that need setuid removed from them
#
# @param required_pkgs
#   Array of strings of package names to install
#
# @param root_k5login_principals
#   Optional Array k5login principals with root privileges
#
# @example
#   include profile_system_auth::kerberos
#
class profile_system_auth::kerberos (
  Optional[String] $ad_computers_ou,      # AD OU FOR COMPUTER OBJECTS
  Optional[String] $ad_createhostkeytab,  # BASE64 ENCODING OF KRB5 CREATEHOST KEYTAB FILE
  Optional[String] $ad_createhostuser,    # AD CREATEHOST USER
  Optional[String] $ad_domain,            # AD DOMAIN
  Hash             $cfg_file_settings,    # cfg files and their contents
  Optional[String] $createhostkeytab,     # BASE64 ENCODING OF KRB5 CREATEHOST KEYTAB FILE
  Optional[String] $createhostuser,       # CREATEHOST USER
  Hash             $crons,
  Optional[String] $domain,               # KERBEROS DOMAIN
  Boolean          $enable,
  Hash             $files_remove_setuid,
  Array[String[1]] $required_pkgs,     # DEFAULT SET VIA MODULE DATA
  Optional[Array[String[1]]] $root_k5login_principals, # PRINCIPALS WITH ROOT PRIVILEGES
) {
  if ($enable) {
    ensure_packages( $required_pkgs )

    File {
      owner  => root,
      group  => root,
      ensure => file,
      mode   => '0644',
    }

    # Remove setuid/setgid from key files
    $file_remove_setuid_defaults = {
      mode    => 'ug-s',
    }
    ensure_resources('file', $files_remove_setuid, $file_remove_setuid_defaults )

    # Ensure directory for include files
    file { '/etc/krb5.conf.d':
      ensure => directory,
      mode   => '0755',
    }

    # CREATE ALL THE FILES LISTED IN THE cfg_file_settings HASH
    $cfg_file_settings.each | $filename, $content | {
      file { $filename:
        content => $content,
      }
    }

    if ( $root_k5login_principals ) {
      file { '/root/.k5login':
        content => join($root_k5login_principals, "\n"),
        mode    => '0600',
      }
    }
    else {
      file { '/root/.k5login':
        ensure => 'absent',
      }
    }

    # KERBEROS HOST PRINCIPAL CREATION
    if ( $createhostkeytab and $createhostuser ) {
      $kerberos_domains = split($facts['kerberos_keytab_domains'], ',')
      if ( $domain in $kerberos_domains ) {
        $ensure_parm = 'absent'
      } else {
        $ensure_parm = 'present'

        exec { 'run_create_host_keytab_script':
          path    => ['/usr/bin', '/usr/sbin', '/usr/lib/mit/bin'],
          command => Sensitive(
            "/root/createhostkeytab.sh '${createhostkeytab}' '${createhostuser}' '${domain}'"
          ),
          require => File['/root/createhostkeytab.sh'],
        }

        # FOLLOWING IS JUST IN CASE THE run_create_host_keytab_script TIMES OUT, WHICH IT HAS
        file { '/root/createhost.keytab':
          ensure  => absent,
          require => Exec['run_create_host_keytab_script'],
        }
      }

      file { '/root/createhostkeytab.sh':
        ensure  => $ensure_parm,
        mode    => '0500',
        content => template("${module_name}/createhostkeytab.sh.erb"),
      }

      Cron {
        user        => 'root',
        hour        => 8,
        minute      => 1,
        environment => ['SHELL=/bin/sh',],
      }
      $crons.each | $k, $v | {
        cron { $k: * => $v }
      }
    }
    else {
      file { '/root/createhostkeytab.sh':
        ensure => absent,
      }
      $crons.each | $k, $v | {
        cron { $k: ensure => absent, }
      }
    }

    # AD JOIN AND KEYTAB CREATION
    if ( $ad_createhostkeytab and $ad_createhostuser and $ad_computers_ou and $ad_domain ) {
      $kerberos_domains = split($facts['kerberos_keytab_domains'], ',')
      if ( $ad_domain in $kerberos_domains ) {
        $ensure_parm = 'absent'
      } else {
        $ensure_parm = 'present'

        exec { 'run_ad_create_host_keytab_script':
          path    => ['/usr/bin', '/usr/sbin', '/usr/lib/mit/bin'],
          command => Sensitive(
            "/root/ad_createhostkeytab.sh '${ad_domain}' '${ad_computers_ou}' '${ad_createhostuser}' '${ad_createhostkeytab}' "
          ),
          require => File['/root/ad_createhostkeytab.sh'],
        }

        # FOLLOWING IS JUST IN CASE THE run_ad_create_host_keytab_script TIMES OUT, WHICH IT HAS
        file { '/root/createhost.keytab':
          ensure  => absent,
          require => Exec['run_ad_create_host_keytab_script'],
        }
      }

      file { '/root/ad_createhostkeytab.sh':
        ensure  => $ensure_parm,
        mode    => '0500',
        content => template("${module_name}/ad_createhostkeytab.sh.erb"),
      }
    }
  }
}
