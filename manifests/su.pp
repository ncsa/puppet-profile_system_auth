# @summary Basic su configuration
#
# @param disable_su
#   Boolean to disable su (disabled by setting permissions on su to 700)
#
# @param su_path
#   Path to the su binary
#
# @example
#   include profile_system_auth::su
class profile_system_auth::su (
  Boolean $disable_su,
  String $su_path,
) {
  if ($disable_su) {
    $mode = '0700'
  } else {
    $mode = '4755'
  }

  file { $su_path :
    owner => 'root',
    group => 'root',
    mode  => $mode,
  }
}
