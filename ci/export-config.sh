#!/usr/bin/env bash
## Usage: [script] [env] [system_domain]
## Examp: ./export-config.sh dev system.codex.starkandwayne.com

if credhub f | grep /$1-bosh/$1-cf/cf_mgmt_client_secret; then
    echo "cf_mgmt_client_secret present!"
else
    echo "Can't find the cf_mgmt_client_secret"
    echo "Please check if you are authenticated in CredHub, from bosh-deployment run 'genesis do [env] credhub-login'"
    echo "Please check if cf-deployment was run with feature that creates this client [ex. ops/cf-mgmt-uaa-client.yml]"
    exit 1
fi

./cf-mgmt export-config\
  --config-dir="ci/config/$1"\
  --system-domain=$2\
  --user-id=cf_mgmt_client\
  --client-secret=$(credhub g -n /$1-bosh/$1-cf/cf_mgmt_client_secret | sed -n 's/value: //p')

./cf-mgmt-config generate-concourse-pipeline --config-dir="ci/config/$1"