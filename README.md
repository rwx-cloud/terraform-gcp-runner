# terraform-google-runner

Grants [RWX](https://www.rwx.com) permission to provision self-hosted runners in
your Google Cloud project. Contact [RWX support](https://www.rwx.com/support) to
enable support for self-hosted runners.

The module creates identities and IAM grants and nothing else. It does not
create networks, subnetworks, firewall rules, or Compute Engine instances — RWX
launches instances into the subnetwork you already have.

- **Workload identity pool and provider** — RWX authenticates to Google Cloud
  with short-lived OIDC tokens rather than a service account key. The provider
  only accepts tokens that RWX issues for this runner.
- **Provisioning service account** (`rwx-provisioning-<id>`) — RWX impersonates
  this service account to launch and delete runners. It may create, inspect,
  and delete Compute Engine instances in the project, and it may only launch
  them into the subnetwork you pass in.
- **Instance service account** (`rwx-runner-<id>`) — the identity your runner
  instances run as. It starts with no roles; grant your own to give builds
  access to your Google Cloud resources.

`<id>` is derived from the external ID that RWX generates for the runner.

The module also enables the IAM, IAM Service Account Credentials, and Security
Token Service APIs in the project. It never disables them.

## Usage

Contact [RWX support](https://www.rwx.com/support) to enable support for
self-hosted runners.

Create a self-hosted Google Cloud runner at [cloud.rwx.com](https://cloud.rwx.com),
then apply this module with the values it shows you. For example:

```hcl
module "rwx_runner" {
  source  = "rwx-cloud/runner/google"
  version = "~> 1.0"

  rwx_self_hosted_runner_label       = "prod"
  rwx_self_hosted_runner_external_id = "019a2b3c4d5e7f6a8b1c0e9b4f71c2a8"
  rwx_oidc_issuer                    = "https://cloud.rwx.com/mint"
  project_id                         = "my-project"
  subnetwork                         = "projects/my-project/regions/us-central1/subnetworks/rwx-runners"
}
```

Runner instances have no external IP address, so the subnetwork needs outbound
internet access through [Cloud NAT](https://cloud.google.com/nat/docs/overview)
or an equivalent. The subnetwork may belong to a Shared VPC host project; the
module grants access to it in that project.

If your organization does not allow modules from the public registry, source it
from git instead. Version constraints are not available on git sources, so pin
an exact tag:

```hcl
module "rwx_runner" {
  source = "git::https://github.com/rwx-cloud/terraform-google-runner.git?ref=v1.0.0"
  # ...
}
```

### Granting your builds access to other Google Cloud resources

Grant roles to the instance service account:

```hcl
resource "google_project_iam_member" "runner_artifact_registry" {
  project = "my-project"
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${module.rwx_runner.instance_service_account_email}"
}
```

## Upgrading

RWX occasionally releases new features that require permissions an older version of
this module did not grant. To upgrade, raise the `version` constraint and re-apply.

## Examples

- [Basic](https://github.com/rwx-cloud/terraform-google-runner/tree/main/examples/basic) - A single runner in one project

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_compute_subnetwork_iam_member.provisioning](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork_iam_member) | resource |
| [google_iam_workload_identity_pool.rwx](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool) | resource |
| [google_iam_workload_identity_pool_provider.rwx](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider) | resource |
| [google_project_iam_custom_role.provisioning](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_custom_role.subnetwork](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_member.provisioning](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.required](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_service_account.provisioning](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account.runner](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.provisioning_federation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_service_account_iam_member.runner_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | ID of the Google Cloud project that runner instances launch in. Every resource this module creates lives in this project, except for the role that grants use of the subnetwork, which lives in the subnetwork's project. | `string` | n/a | yes |
| <a name="input_rwx_oidc_issuer"></a> [rwx\_oidc\_issuer](#input\_rwx\_oidc\_issuer) | URL of the OIDC issuer that signs the tokens RWX presents to Google Cloud. Look it up on cloud.rwx.com. | `string` | n/a | yes |
| <a name="input_rwx_self_hosted_runner_external_id"></a> [rwx\_self\_hosted\_runner\_external\_id](#input\_rwx\_self\_hosted\_runner\_external\_id) | External ID that RWX generates for this self-hosted runner configuration; look it up on cloud.rwx.com. The workload identity provider only accepts tokens RWX issues for this runner, and the names of the resources this module creates are derived from it. | `string` | n/a | yes |
| <a name="input_rwx_self_hosted_runner_label"></a> [rwx\_self\_hosted\_runner\_label](#input\_rwx\_self\_hosted\_runner\_label) | Label of the self-hosted runner configuration on cloud.rwx.com. Set `runner.self-hosted` to this value in an RWX run definition to route tasks to this runner configuration. | `string` | n/a | yes |
| <a name="input_subnetwork"></a> [subnetwork](#input\_subnetwork) | Full resource name of the subnetwork that RWX launches runner instances into, in the form `projects/PROJECT/regions/REGION/subnetworks/NAME`. The provisioning service account may use this subnetwork and no other. It may belong to a Shared VPC host project. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_instance_service_account_email"></a> [instance\_service\_account\_email](#output\_instance\_service\_account\_email) | Email of the service account that runner instances run as. Grant it roles to give your builds access to other Google Cloud resources. |
| <a name="output_provisioning_service_account_email"></a> [provisioning\_service\_account\_email](#output\_provisioning\_service\_account\_email) | Email of the service account RWX impersonates to manage runners in this project. |
| <a name="output_workload_identity_provider"></a> [workload\_identity\_provider](#output\_workload\_identity\_provider) | Full resource name of the workload identity provider RWX authenticates through. |
<!-- END_TF_DOCS -->

## License

MIT. See [LICENSE](LICENSE).
