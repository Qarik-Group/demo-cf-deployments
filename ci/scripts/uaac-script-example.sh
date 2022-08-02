#!/usr/bin/env bash
set -x
uaac group add cloud_controller.admin_read_only
#LDAP, but can be changed with `--origin okta`` to OKTA ;)
uaac group map --name scim.read "CF_ENV_ADMIN"
uaac group map --name scim.write "CF_ENV_ADMIN"
uaac group map --name cloud_controller.admin "CF_ENV_ADMIN"
