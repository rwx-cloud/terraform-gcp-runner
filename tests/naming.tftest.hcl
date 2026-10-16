# RWX derives these names from the external ID rather than reading them from
# Terraform, so changing any of them breaks runners that RWX already knows about.

mock_provider "google" {
  mock_resource "google_iam_workload_identity_pool" {
    defaults = {
      name = "projects/123456789012/locations/global/workloadIdentityPools/rwx-runner-0e9b4f71c2a8"
    }
  }
}

override_resource {
  target = google_service_account.provisioning
  values = {
    name  = "projects/runner-project/serviceAccounts/rwx-provisioning-0e9b4f71c2a8@runner-project.iam.gserviceaccount.com"
    email = "rwx-provisioning-0e9b4f71c2a8@runner-project.iam.gserviceaccount.com"
  }
}

override_resource {
  target = google_service_account.runner
  values = {
    name  = "projects/runner-project/serviceAccounts/rwx-runner-0e9b4f71c2a8@runner-project.iam.gserviceaccount.com"
    email = "rwx-runner-0e9b4f71c2a8@runner-project.iam.gserviceaccount.com"
  }
}

variables {
  rwx_self_hosted_runner_label       = "prod"
  rwx_self_hosted_runner_external_id = "019a2b3c4d5e7f6a8b1c0e9b4f71c2a8"
  rwx_oidc_issuer                    = "https://cloud.rwx.com/mint"
  project_id                         = "runner-project"
  subnetwork                         = "projects/network-host/regions/us-central1/subnetworks/runners"
}

run "names_match_rwx" {
  command = apply

  assert {
    condition     = google_service_account.provisioning.account_id == "rwx-provisioning-0e9b4f71c2a8"
    error_message = "Unexpected provisioning service account ID."
  }

  assert {
    condition     = google_service_account.runner.account_id == "rwx-runner-0e9b4f71c2a8"
    error_message = "Unexpected instance service account ID."
  }

  assert {
    condition     = google_iam_workload_identity_pool.rwx.workload_identity_pool_id == "rwx-runner-0e9b4f71c2a8"
    error_message = "Unexpected workload identity pool ID."
  }

  assert {
    condition     = google_iam_workload_identity_pool_provider.rwx.workload_identity_pool_provider_id == "rwx-cloud"
    error_message = "Unexpected workload identity provider ID."
  }
}

run "trusts_only_this_runner" {
  command = apply

  assert {
    condition     = google_iam_workload_identity_pool_provider.rwx.attribute_condition == "assertion.sub == 'rwx:provisioning:019a2b3c4d5e7f6a8b1c0e9b4f71c2a8'"
    error_message = "The provider must only accept this runner's provisioning subject."
  }

  assert {
    condition     = google_iam_workload_identity_pool_provider.rwx.oidc[0].allowed_audiences == tolist(["//iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/rwx-runner-0e9b4f71c2a8/providers/rwx-cloud"])
    error_message = "The provider must accept the audience RWX presents."
  }

  assert {
    condition     = google_service_account_iam_member.provisioning_federation.member == "principal://iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/rwx-runner-0e9b4f71c2a8/subject/rwx:provisioning:019a2b3c4d5e7f6a8b1c0e9b4f71c2a8"
    error_message = "Only this runner's federated subject may impersonate the provisioning service account."
  }
}

run "subnetwork_role_lives_in_the_subnetwork_project" {
  command = apply

  assert {
    condition     = google_project_iam_custom_role.subnetwork.project == "network-host" && google_compute_subnetwork_iam_member.provisioning.project == "network-host"
    error_message = "The subnetwork role must be defined and granted in the subnetwork's project."
  }

  assert {
    condition     = google_compute_subnetwork_iam_member.provisioning.region == "us-central1" && google_compute_subnetwork_iam_member.provisioning.subnetwork == "runners"
    error_message = "The subnetwork grant must target the configured subnetwork."
  }

  assert {
    condition     = google_project_iam_custom_role.provisioning.project == "runner-project"
    error_message = "The provisioning role must be defined in the runner project."
  }
}
