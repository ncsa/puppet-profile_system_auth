# profile_system_auth

![pdk-validate](https://github.com/ncsa/puppet-profile_system_auth/workflows/pdk-validate/badge.svg)
![yamllint](https://github.com/ncsa/puppet-profile_system_auth/workflows/yamllint/badge.svg)

NCSA Common Puppet Profiles - configure standard system authentication


## Description

This common puppet profile module configures standard system authentication as
used by NCSA. It configures kerberos, ldap, sssd, and general authentication.


## Dependencies
- https://github.com/ncsa/puppet-sssd


* `authselect` (or `authconfig` for EL7)
* kerberos client and NCSA's kerberos configuration
* kerberos host key creation and renewal (optional)
* ldap clients and NCSA's ldap configuration
* sssd configuration
=======
## Reference

[REFERENCE.md](REFERENCE.md)


## Usage

The goal is that no paramters are required to be set. The default paramters should work for most NCSA deployments out of the box.

But there are two sets of parameters you may desire to override.

### Disabling Homedir Creation

If you do not want to enable automtic homedir creation when a user logs into a host, you will want to set `profile_system_auth::config::enablemkhomedir` = `false`. This defaults to `true`, but may not be desirable in some environments.

### Creating and Updating Kerberos Hostkeys

NCSA allows `createhost` principals for projects. This allows for two automated tasks related to Kerberos hostkeys:
- automated creation of Kerberos hostkeys of servers
- renewal (and cleanup) of Kerberos hostkeys of servers

In order to support this, you need to request a `createhost` principal keytab for your project, then assign the base64 encoding of the keytab file to `profile_system_auth::kerberos::createhostkeytab` and the first part of the principal's username to `profile_system_auth::kerberos::createhostuser` parameters. NCSA staff can request a `createhost` principal by emailing service@ncsa.illinois.edu. They will provide you a principal username and either the keytab file for that user or a BASE64 encoding of that keytab.
