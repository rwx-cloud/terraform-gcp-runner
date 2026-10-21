terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}

provider "google" {}

# The rwx_self_hosted_runner_label, rwx_self_hosted_runner_external_id, and
# rwx_oidc_issuer values below are provided by RWX when you configure a
# self-hosted runner — copy them directly from the runner setup page at
# cloud.rwx.com. The project_id and subnetwork reference resources in your own
# Google Cloud organization.
module "rwx_runner" {
  source  = "rwx-cloud/runner/gcp"
  version = "~> 1.0"

  rwx_self_hosted_runner_label       = "prod"
  rwx_self_hosted_runner_external_id = "019a2b3c4d5e7f6a8b1c0e9b4f71c2a8"
  rwx_oidc_issuer                    = "https://cloud.rwx.com/mint"
  project_id                         = "my-project"
  subnetwork                         = "projects/my-project/regions/us-central1/subnetworks/rwx-runners"
}

output "instance_service_account_email" {
  value = module.rwx_runner.instance_service_account_email
}
