# profile_system_auth::kerberos
#
# @summary Basic kerberos client setup, with optional host principal management
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
  Hash               $cfg_file_settings, # cfg files and their contents
  Optional[ String ] $createhostkeytab,  # BASE64 ENCODING OF KRB5 CREATEHOST KEYTAB FILE
  Optional[ String ] $vaultkeytabkey,    # The key to the base64 encoded hostkeytab in vault
  Optional[ String ] $vaultsecretdir,    # Directory where the secret is located in vault
  Optional[ String ] $createhostuser,    # CREATEHOST USER
  Hash               $crons,
  Hash               $files_remove_setuid,
  Array[ String[1] ] $required_pkgs,     # DEFAULT SET VIA MODULE DATA
  Optional[ Array[ String[1] ] ] $root_k5login_principals, # PRINCIPALS WITH ROOT PRIVILEGES
) {

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

  if ( $root_k5login_principals )
  {
    file { '/root/.k5login':
      content => join($root_k5login_principals, "\n"),
      mode    => '0600',
    }
  }
  else
  {
    file { '/root/.k5login':
      ensure => 'absent',
    }
  }

  if (lookup(profile_secrets::enable))
  {
    $vault_uri = profile_secrets::lookup_uri($vaultsecretdir)
    $vault_auth = lookup(profile_secrets::vault_authmethod)
    $vault_kv_version = lookup(profile_secrets::vault_kv_version)
    $hostkeytabbase64 = vault_key($vault_uri,$vault_auth,$vaultkeytabkey,$vault_kv_version)
    notify { 'get_createhost_vault' :
      message => $hostkeytabbase64,
  }
  else
  {
    $hostkeytabbase64 = $createhostkeytab
  }

  if ( $hostkeytabbase64 and $createhostuser )
  {
    # CREATE KEYS AND SETUP RENEWAL
    file { '/root/createhostkeytab.sh':
      ensure => present,
      mode   => '0700',
      source => "puppet:///modules/${module_name}/root/createhostkeytab.sh",
    }
    ## THIS MIGHT NEED TO BE SMARTER TO ALLOW FOR MULTIPLE HOSTNAMES ON ONE SERVER
    exec { 'create_host_keytab':
      path    => [ '/usr/bin', '/usr/sbin'],
      command => "/root/createhostkeytab.sh ${hostkeytabbase64} ${createhostuser}",
      unless  => 'klist -kt /etc/krb5.keytab 2>&1 | grep "host/`hostname -f`@NCSA.EDU"',
      require => [
        File[ '/root/createhostkeytab.sh' ],
      ]
    }

    Cron {
      user        => 'root',
      hour        => 8,
      minute      => 1,
      environment => ['SHELL=/bin/sh', ],
    }
    $crons.each | $k, $v | {
      cron { $k: * => $v }
    }
  }
  else
  {
    file { '/root/createhostkeytab.sh':
      ensure => absent,
    }
    $crons.each | $k, $v | {
      cron { $k: ensure => absent, }
    }
  }
}

