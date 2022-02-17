cf deployments
==============================

This repository contains the YAML templates that make up a series of
cf BOSH deployments, using the format prescribed by the
[Genesis][1] utility. These deployments are based off of the
[cf-genesis-kit][2].

Environment Naming
------------------

Each environment managed by this repository will have its own
deployment file, e.g. `us-east-prod.yml`. However, in many cases,
it can be desirable to share param configurations, or kit configurations
across all of the environments, or specific subsets. Genesis supports
this by splitting environment names based on hypthens (`-`), and finding
files with common prefixes to include in the final manifest.

For example, let's look at a scenario where there are three environments
deployed by genesis: `us-west-prod.yml`, `us-east-prod.yml`, and `us-east-dev.yml`.
If there were configurations that should be shared by all environments,
they should go in `us.yml`. Configurations shared by `us-east-dev` and `us-east-prod`
would go in `us-east.yml`.

To see what files are currently in play for an environment, you can run
`genesis <environment-name>`

Quickstart
----------

To create a new environment (called `us-east-prod-cf`):

    genesis new us-east-prod

To build the full BOSH manifest for an environment:

    genesis manifest us-east-prod

... and then deploy it:

    genesis deploy us-east-prod

To rotate credentials for an environment:

    genesis rotate-secrets us-east-prod
    genesis deploy us-east-prod

To change the secrets provider for the environments in this repo:

    genesis secrets-provider --url https://example.com:8200 --insecure

... or clear it to use safe's currently targeted vault:

    genesis secrets-provider --clear

By default, the provider for kits is https://github.com/genesis-community, but
you can set this to another provider url via the `genesis kit-provider`
command:

    genesis kit-provider https://github.mycorp.com/mygenesiskits

This requires that url to provide releases in the same manner as github does.
You can see the current kit provider by calling it with no argument, or revert
back to default with the `--clear` option.

To update the Concourse Pipeline for this repo:

    genesis repipe

To check for updates for this kit:

    genesis list-kits -u

To download a new version of the kit, and deploy it:

    genesis download cf [version] # omitting version downloads the latest

    # update the environment yaml to use the desired kit version,
    # this might be in a different file if using CI to propagate
    # deployment upgrades (perhaps us.yml)
    vi us-east-prod.yml

    genesis deploy us-east-prod.yml     # or commit + git push to have
                                        # CI run through the upgrades

See the [Deployment Pipeline Documentation][3] for more
information on getting set up with Concourse deployment pipelines.

Helpful Links
-------------

- [cf-genesis-kit][2] - Details on the kit used in this repo,
  its features, prerequesites, and params.

- [Deployment Pipeline Documentation][3] - Docs on all the
  configuration options for `ci.yml`, and how the automated
  deployment pipelines behave.

[1]: https://github.com/starkandwayne/genesis
[2]: https://github.com/genesis-community/cf-genesis-kit
[3]: https://github.com/starkandwayne/genesis/blob/master/docs/PIPELINES.md

Repo Structure
--------------

Most of the meat of the deployment repo happens at the base level.
Envirionment YAML files, shared YAML files, and the CI
configuration YAML file will all be here.

The `.genesis/manifests` directory saves redacted copies of the
deployment manifests as they are deployed, for posterity, and to
keep track of any `my-env-name-state.yml` files from `bosh create-env`.

The `.genesis/cached` directory is used by CI to propagate changes
for shared YAML files along the pipelines. To aid in CI deploys, the
`genesis/bin` directory contains an embedded copy of genesis.

`.genesis/kits` contains copies of the kits that have been used in
this deployment. Once a kit is no longer used in any environment,
it can be safely removed.

`.genesis/config` is used internally by `genesis` to understand
what is being deployed, and how.
