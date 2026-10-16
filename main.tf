locals {
  # RWX derives these resource names from the external ID to find them, so they
  # must not change. The last 12 characters are the random part of the ID; the
  # full ID would not fit in a service account ID.
  name_suffix = substr(var.rwx_self_hosted_runner_external_id, 20, 12)

  provisioning_service_account_id = "rwx-provisioning-${local.name_suffix}"
  instance_service_account_id     = "rwx-runner-${local.name_suffix}"
  workload_identity_pool_id       = "rwx-runner-${local.name_suffix}"
  workload_identity_provider_id   = "rwx-cloud"

  provisioning_subject = "rwx:provisioning:${var.rwx_self_hosted_runner_external_id}"

  subnetwork = regex("^projects/(?P<project>[^/]+)/regions/(?P<region>[^/]+)/subnetworks/(?P<name>[^/]+)$", var.subnetwork)

  required_services = toset([
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
  ])
}

resource "google_project_service" "required" {
  for_each = local.required_services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_iam_workload_identity_pool" "rwx" {
  project                   = var.project_id
  workload_identity_pool_id = local.workload_identity_pool_id
  display_name              = "RWX runner ${local.name_suffix}"
  description               = "Lets RWX authenticate as the provisioning service account for self-hosted runner ${var.rwx_self_hosted_runner_label}."

  depends_on = [google_project_service.required]
}

resource "google_iam_workload_identity_pool_provider" "rwx" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.rwx.workload_identity_pool_id
  workload_identity_pool_provider_id = local.workload_identity_provider_id
  display_name                       = "RWX"
  description                        = "Trusts tokens RWX issues for self-hosted runner ${var.rwx_self_hosted_runner_label}."

  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
  attribute_condition = "assertion.sub == '${local.provisioning_subject}'"

  oidc {
    issuer_uri        = var.rwx_oidc_issuer
    allowed_audiences = ["//iam.googleapis.com/${google_iam_workload_identity_pool.rwx.name}/providers/${local.workload_identity_provider_id}"]
  }
}

resource "google_service_account" "provisioning" {
  project      = var.project_id
  account_id   = local.provisioning_service_account_id
  display_name = "RWX provisioning (${var.rwx_self_hosted_runner_label})"
  description  = "Allows RWX to provision and tear down self-hosted runners in this project."

  depends_on = [google_project_service.required]
}

resource "google_service_account_iam_member" "provisioning_federation" {
  service_account_id = google_service_account.provisioning.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.rwx.name}/subject/${local.provisioning_subject}"
}

resource "google_project_iam_custom_role" "provisioning" {
  project     = var.project_id
  role_id     = "rwx_provisioning_${local.name_suffix}"
  title       = "RWX provisioning (${var.rwx_self_hosted_runner_label})"
  description = "Create, inspect, and delete RWX self-hosted runner instances."
  permissions = [
    "compute.disks.create",
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.get",
    "compute.instances.setLabels",
    "compute.instances.setMetadata",
    "compute.instances.setServiceAccount",
    "compute.zoneOperations.get",
  ]
}

resource "google_project_iam_member" "provisioning" {
  project = var.project_id
  role    = google_project_iam_custom_role.provisioning.name
  member  = "serviceAccount:${google_service_account.provisioning.email}"
}

# Custom roles can only be granted in the project that defines them, so this one
# lives in the subnetwork's project, which differs from var.project_id when the
# subnetwork belongs to a Shared VPC host project.
resource "google_project_iam_custom_role" "subnetwork" {
  project     = local.subnetwork.project
  role_id     = "rwx_subnetwork_${local.name_suffix}"
  title       = "RWX subnetwork (${var.rwx_self_hosted_runner_label})"
  description = "Launch RWX self-hosted runner instances into a subnetwork, without external IP addresses."
  permissions = ["compute.subnetworks.use"]
}

resource "google_compute_subnetwork_iam_member" "provisioning" {
  project    = local.subnetwork.project
  region     = local.subnetwork.region
  subnetwork = local.subnetwork.name
  role       = google_project_iam_custom_role.subnetwork.name
  member     = "serviceAccount:${google_service_account.provisioning.email}"
}

resource "google_service_account" "runner" {
  project      = var.project_id
  account_id   = local.instance_service_account_id
  display_name = "RWX runner (${var.rwx_self_hosted_runner_label})"
  description  = "Identity that RWX self-hosted runner instances run as."

  depends_on = [google_project_service.required]
}

resource "google_service_account_iam_member" "runner_user" {
  service_account_id = google_service_account.runner.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.provisioning.email}"
}
