# Motivation
The story behind the functionality presented below comes from the clients that leverage Genesis Project in their environments to automate creation of CloudFoundry and it assisting components.\
At some point clients created a multi-env (>10 environments) genesis backed deployments for CloudFoundry using [`genesis repipe`](https://github.com/genesis-community/genesis/blob/main/docs/PIPELINES.md) to configure, design and generate Concourse pipeline.\
`genesis repipe` allows users to generate for each env two jobs, one for executing `genesis deploy $env` and second that notifies about the change `notify $env deployed`.\
At some point clients wanted to extend the functionality in that pipeline to for example include post-deploy steps like secret rotations per env, internal domains creations, application security groups configuration and bindings, and many more.\
Thanks to the fact that Genesis Project widely adopted [spruce](https://github.com/geofffranks/spruce) creation of such custom functionality was possible by appending to the generated pipeline a new tasks or jobs which were executing the desire features.

For the CloudFoundry the amount of such post-deploy features to be executed per each env can become quite big over the time. Also we would need a place to store for ex. definitions for ASG rules, organizations & spaces hierarchy and all kind of various bindings.\
For that purpose the custom implementation could be made, but this documentation and implementation covers the usage of [cf-mgmt]() project.\
[cf-mgmt docs]() include a variety of commands for end-users to create, modify or destroy resources on CloudFoundry using the code repository as a single source of truth medium to store each environment configuration under SVC system. By modifying the code in that repository the operators can manage the entire CloudFoundry foundation using the code vs CLI.

This approach brings equally benefits and challenges, most recognized benefit to be a fact that configuration is now visible and the state of the deployment is known, as well as it can be restored from any point of time thanks to the SVC system.\
One of the biggest challenge in that approach is the mindset shift that configuration is now not the result of applied commands to the platform, but the code itself.
>Some other concepts that share principles similar to cf-mgmt:
>- [Infrastructure as a Code](https://www.techtarget.com/searchitoperations/definition/Infrastructure-as-Code-IAC)
>- [gitops approach](https://www.gitops.tech/)
>- [ArgoCD as example of gitops implementation](https://github.com/argoproj/argo-cd/blob/master/README.md)
# Design & Architecture
#### UX flow when providing a change
```mermaid
  flowchart LR
    A[user] -->|modify| B[config-repository]
    subgraph automatically triggered
    direction LR
    B -->|trigger| C(concourse-pipeline)
    C -->|run| D[first-env deploy]
    D -->|success| E[first-env configure]
    D -->|failure| F[notify]
    D -->|success| F
    E -->|modify| G[first-env cloud-foundry]
    end
    subgraph manually triggered
    direction RL
    F -->|send to| K[operator]
    K -->|trigger| L[second-env deploy]
    L -->|success| M[second-env configure]
    L -->|failure| N[notify]
    L -->|success| N
    end
```
#### UX flow when only CF config changes
```mermaid
  flowchart LR
    A[user] -->|modify| B[config-repository]
    B -->|trigger| D(concourse-pipeline)
    D --> E[first-env configure]
    D --> F[second-env configure]
    subgraph first-env
    direction LR
    E -->|modify| G[first-env cloud-foundry]
    end
    subgraph  second-env
    direction LR
    F -->|modify| H[first-env cloud-foundry]
    end
```
# Setup
## CloudFoundry
#### Setup cf-mgmt UAA client, put the content into your cf-genesis-kit/ops/*.yml
-----
```yaml
instance_groups:
- name: uaa
  jobs:
  - name: uaa
    properties:
      uaa:
        clients:
          cf_mgmt_client:
            resource_ids: none
            authorized-grant-types: client_credentials,refresh_token
            authorities: routing.router_groups.read,scim.write,scim.read,cloud_controller.admin
            autoapprove:
            scope: routing.router_groups.read,scim.write,scim.read,cloud_controller.admin
            secret: ((cf_mgmt_client_secret))

variables:
- name: cf_mgmt_client_secret
  type: password
```
## cf-mgmt
#### Get cf-mgmt CLI tools:
```bash
wget https://github.com/vmware-tanzu-labs/cf-mgmt/releases/download/v1.0.52/cf-mgmt-linux
wget https://github.com/vmware-tanzu-labs/cf-mgmt/releases/download/v1.0.52/cf-mgmt-config-linux

mv cf-mgmt-linux cf-mgmt
mv cf-mgmt-config-linux cf-mgmt-config
```
You may want to move those binaries somewhere else and alias them under you bash/zsh/any-sh profiles, but usually the range of use is unitary.

#### Export configuration, or initialise new one.
Initialisation should happen only if you are connecting cf-mgmt configuration to a brand new CF deployment. If there are Orgs/Spaces/Quotas/ASG's etc already setup you may want to export it instead of overriding.

From this repository root run:
```bash
./ci/export-config.sh
```
export-config documentation: https://github.com/vmware-tanzu-labs/cf-mgmt/blob/main/docs/export-config/README.md

This should create a new directory called `config` at the top level. 

### Concourse Pipeline generation
With the `config/` dir generated let's now run CI generation:
```bash
./cf-mgmt-config generate-concourse-pipeline
```
This should create two things:
- a dir named `ci`
- a yml file named `pipeline.yml`

What it did was it generated a multiple Concourse `jobs` that all call the same `task` which just executes `cf-mgmt` with correct input of parameters regarding what resource needs to be modified on CloudFoundry side.

**Add config/vars.yml to .gitignore**

It should not be pushed to the remote repository (or it can if you don't have plain text passwords in it ;-) )

Example `config/vars.yml`
```yaml
# your git repo uri
git_repo_uri: "https://github.com/starkandwayne/demo-cf-mgmt-deployments"
git_repo_branch: main
# your cf system domain
system_domain: "system.codex.starkandwayne.com"
# user account with permission to create orgs/spaces
user_id: "cf_mgmt_client"
# DEPRECATED - Use client_secret - password of user account with permission to create orgs/spaces
password: ""
# client secret for uaa for user_id
client_secret: "[read it via \"credhub g -n /dev-bosh/dev-cf/cf_mgmt_client_secret | sed -n 's/value: //p'\""

# logging level for cf-mgmt commands in the pipeline
log_level: INFO
# time interval to trigger update/delete jobs on
time-trigger: 15m

# configuration directory
config_dir: config

# allow specifying ldap server in pipeline vs in ldap.yml only needed if using LDAP
ldap_server: ""

# allow specifying ldap bind user in pipeline vs in ldap.yml only needed if using LDAP
ldap_user: ""

# password to bind to ldap - only needed if using LDAP
ldap_password: ""
```

### Extending configuration
To extend or modify current configuration please use `./cf-mgmt-config` CLI or do it directly by modifying and creating files.\
`./cf-mgmt-config` is mostly generating new yml files with some templates in them so it may be useful at the beginning.

### Testing
Manually executed set of tests that can be also useful for learning cf-mgmt

#### Create org and space
To create a new org and space just copy a template of existing one and modify it to your needs.\
Or run new init via `./cf-mgmt-config add-org --org test`.\
For the sake of this testing/tutorial we assume `cf-mgmt-org` exists with space `cf-mgmt-space` in it.\
Take a look here for example: https://github.com/starkandwayne/demo-cf-mgmt-deployments/tree/main/config/cf-mgmt-org

#### Create user in org/space
Same steps are for org or space, just modify space config vs org config ;-)\
First we need to create a new user in UAA or have connected LDAP.\
If you are using LDAP, just configure user in `ldap.yml` as docs says.\

Create user:
```bash
uaac user add test --emails "test@test" --password test
uaac member add scim.read test
uaac member add clients.read test
```

Let's now add it under our `cf-mgmt-org`, modify `config/cf-mgmt-org/orgConfig.yml`:
```diff
org-manager:
  ldap_users: []
  users:
  - admin
+ - test
```

Execute a dry run:
```bash
./local-cf-mgmt update-org-users --peek
```
You should see output similar to this one:
```log
2022/07/25 12:38:50 I0725 12:38:50.904103 1786254 users.go:267] [dry-run]: Add User test to role manager for org cf-mgmt-org
```
And from the `cf cli`:
```bash
> cf org-users cf-mgmt-org
Getting users in org cf-mgmt-org as admin...

ORG MANAGER
  admin
  test

BILLING MANAGER
  No BILLING MANAGER found

ORG AUDITOR
  No ORG AUDITOR found
```

#### Create quotas and bind it to org/space
Same steps are for org or space, just modify space config vs org config ;-)

Let's start with creating new quota. If you want to use existing one, just skip this step.

Create new file under `config/org_quotas/` named `cf-mgmt-quota.yml` and copy `default` quota configuration to it.
```bash
cat default.yml > cf-mgmt-quota.yml
```
Modify config:
```diff
total_private_domains: unlimited
total_reserved_route_ports: "100"
total_service_keys: unlimited
-app_instance_limit: unlimited
+app_instance_limit: 10
app_task_limit: unlimited
-memory-limit: 100G
+memory-limit: 20G
instance-memory-limit: unlimited
-total-routes: "1000"
+total-routes: "100"
total-services: unlimited
paid-service-plans-allowed: true
```

Now use this quota in `cf-mgmt-org`, modify `config/cf-mgmt-org/orgConfig.yml`:
```diff
-named_quota: default
+named_quota: cf-mgmt-quota
```

Let's test that new quota:
```log
> ./local-cf-mgmt update-org-quotas --peek
2022/07/25 13:16:47 I0725 13:16:47.884558 1837380 quota.go:419] [dry-run]: create org quota cf-mgmt-quota
2022/07/25 13:16:47 I0725 13:16:47.924608 1837380 quota.go:443] [dry-run]: assign quota dry-run-quota to org cf-mgmt-org
```

Verify the quota is applied:
```bash
cf quotas
cf org cf-mgmt-org
```
Should show new quota, it params, and that it is now used by `cf-mgmt-org`.

#### Create ASG's
There are two types of ASG's: default ones and all others ;-)\
Each ASG is applied during `runtime`, `staging` or for both.\
Let's go first and create a new `default` ASG, `default` ones applies to both `staging` and `runtime` and are not scoped - they apply to entire CF deployment.

Under `config/defaults_asgs/` create new file called `private_networks.json` with a content:
```json
[
  {
    "protocol": "tcp",
    "destination": "10.0.0.0-10.255.255.255",
    "ports": "443"
  },
  {
    "protocol": "tcp",
    "destination": "172.16.0.0-172.31.255.255",
    "ports": "443"
  },
  {
    "protocol": "tcp",
    "destination": "192.168.0.0-192.168.255.255",
    "ports": "443"
  }
]
```
And let's see if that applies:
```bash
> ./local-cf-mgmt create-security-groups --peek
2022/07/25 13:40:30 I0725 13:40:30.85259 1868840 securitygroup.go:332] [dry-run]: creating securityGroup private_networks with contents [
  {
    "protocol": "tcp",
    "destination": "10.0.0.0-10.255.255.255",
    "ports": "443"
  },
  {
    "protocol": "tcp",
    "destination": "172.16.0.0-172.31.255.255",
    "ports": "443"
  },
  {
    "protocol": "tcp",
    "destination": "192.168.0.0-192.168.255.255",
    "ports": "443"
  }
]
```

Let's go ahead now and actually create the **global** ASG for our space `cf-mgmt-space`.\
Under `config/asgs/` create new file called `cf-mgmt-asg.json` with a content:
```json
[
	{
		"protocol": "tcp",
		"ports": "7007,7008",
		"destination": "0.0.0.0/0",
		"code": 0,
		"type": 0
	}
]
```
Update the `config/cf-mgmt-org/cf-mgmt-space/spaceConfig.yml`
```diff
-enable-security-group: false
+enable-security-group: true
(...)
-named-security-groups: []
+named-security-groups: [cf-mgmt-asg]
```
And global config file `config/cf-mgmt.yml`:
```diff
-enable-unassign-security-groups: false
+enable-unassign-security-groups: true # !!change it only if all ASGs are controlled by cf-mgmt!!
(...)
staging-security-groups:
 - public_networks
 - dns
+ - private_networks
```

Let's test if it works:
```bash
> ./local-cf-mgmt create-security-groups --peek
2022/07/25 13:48:08 I0725 13:48:08.896168 1878661 securitygroup.go:332] [dry-run]: creating securityGroup cf-mgmt-asg with contents [
        {
                "protocol": "tcp",
                "ports": "7007,7008",
                "destination": "0.0.0.0/0",
                "code": 0,
                "type": 0
        }
]
```
```bash
> ./local-cf-mgmt update-space-security-groups --peek

```

If we want to only create a security group for specific space and not actually share it globally there is a way.\
Under `config/cf-mgmt-org/cf-mgmt-space/security-group.json` add a new security group.\
Then we need to enable this ASG create mode by turning this flag under `spaceConfig.yml`:
```diff
-enable-security-group: false
+enable-security-group: true
```

#### Create and enable isolation segments
Isolation segments needs to be first installed by platform engineering team.\
Make sure the CF-Genesis-Kit has feature flag `isolation-segments` enabled, and that the `params:` section include the configuration of isolation segments.\
Use the names from kit `params:` to refer isolation segment.\
Example `cf-genesis-kit` configuration (available since `v2.2.1-rc.1` kit version):
```yaml
params:
  base_domain: cf.testing.example
  isolation_segments:
  - name: custom-params-group
    azs:
    - custom-az
    instances: 5
    vm_type: small-highmem
    network_name: ((cf_runtime_network))
    stemcell: test
    vm_extensions:
    - 100GB_ephemeral_disk
    - cf-router-network-properties
  - name: default-params-group
    azs:
    - z1 
```
To use `default-params-group` or `custom-params-group` segments created by above configuration we only need to edit config in `orgConfig.yml` or `spaceConfig.yml` and include them under `default_isolation_segment` / `isolation_segment` respectively.\
There is no command under `cf-mgmt-config` to add those.

**NOTE: The CloudFoundry never verifies if underlying infrastructure for Isolation Segments exists when performing cf/api operations. Meaning that you can create segments via cf CLI and enable them, without actual VMs running through BOSH. Please verify with platform engineering team if there are problems with isolation segments.**

Let's test it:
```bash
> ./local-cf-mgmt isolation-segments --peek
2022/07/26 11:48:37 I0726 11:48:37.47125 3496941 isolation_segment.go:386] create segment test
2022/07/26 11:48:37 I0726 11:48:37.784086 3496941 isolation_segment.go:411] entitle org 23e733ec-857b-4cfe-8986-6a6536807d81 to iso segment test
2022/07/26 11:48:38 I0726 11:48:38.302575 3496941 isolation_segment.go:362] set isolation segment for space cf-mgmt-space to test (org cf-mgmt-org)
```

If you would like to remove isolation segments when no longer used, not only "unbind" them from org or space, please switch the flag for `enable-delete-isolation-segments` in `cf-mgmt.yml`.

