# profile_system_auth

## Reference

### `profile_system_auth::config`

#### Parameters

##### `enablemkhomedir`

Enables user homedirs to be created upon login. Valid options: 'boolean'.

Default: 'true'.

##### `oddjobd_mkhomedir_conf`

Used to override the value of `/etc/oddjob.d/oddjobd-mkhomedir.conf`. Valid options: 'string'.

##### `required_pkgs`

List of required packages for authcfg, oddjob, etc. Valid options: 'array of strings'.

### `profile_system_auth::kerberos`

#### Parameters

##### `cfg_file_settings`

Hash of kerberos configuration files and their contents. Valid options: 'hash'.

##### `createhostkeytab`

Optional base64 encoding of the kerberos5 createhost keytab file used to create new host keytabs. Valid options: 'string'.

##### `createhostuser`

Optional kerberos5 username of createhost principal. Valid options: 'string'.

##### `crons`

Hash of puppet cron resources used to renew and cleanup hostkeys.

##### `required_pkgs`

List of required packages for kerberos. Valid options: 'array of strings'.

##### `root_k5login_prinicipals`

Optional list of kerberos principals that are allowed root access. Valid options: 'array of strings'.

### `profile_system_auth::ldap`

#### Parameters

##### `ldap_conf`

LDAP configuration file contents. Valid options: 'string'.

##### `required_pkgs`

List of required packages for ldap clients. Valid options: 'array of strings'.

