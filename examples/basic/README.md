# Basic example

Grants RWX permission to manage self-hosted runners in a single Google Cloud
project.

Replace `rwx_self_hosted_runner_label`, `rwx_self_hosted_runner_external_id`,
`rwx_oidc_issuer`, `project_id`, and `subnetwork` with the values you
configured for your self-hosted runner at [cloud.rwx.com](https://cloud.rwx.com),
then:

```console
terraform init
terraform apply
```
