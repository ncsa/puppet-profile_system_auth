# @summary Setup default system auth
#
# Setup system auth: authselect/authconfig, kerberos, ldap, sssd, etc
#
# @example
#   include profile_system_auth
class profile_system_auth {
  include profile_system_auth::config
  include profile_system_auth::kerberos
  include profile_system_auth::ldap
  include profile_system_auth::su
  include sssd
}
