# @summary Basic ldap client setup
#
# Basic ldap client setup
#
# @example
#   include profile_system_auth::ldap
class profile_system_auth::ldap (
  String             $ldap_conf,     # ldap.conf file contents
  Array[ String[1] ] $required_pkgs, # DEFAULT SET VIA MODULE DATA
) {

  ensure_packages( $required_pkgs )

  $file_defaults = {
    owner  => root,
    group  => root,
    ensure => file,
    mode   => '0644',
  }
  file {
    '/etc/openldap':
      ensure => directory,
      mode   => '0755',
    ;
    default: * => $file_defaults
    ;
  }
  file {
    '/etc/openldap/ldap.conf':
      content => $ldap_conf,
      require => File['/etc/openldap'],
    ;
    default: * => $file_defaults
    ;
  }

}
