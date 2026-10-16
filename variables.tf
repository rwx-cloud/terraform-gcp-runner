variable "rwx_self_hosted_runner_label" {
  description = "Label of the self-hosted runner configuration on cloud.rwx.com. Set `runner.self-hosted` to this value in an RWX run definition to route tasks to this runner configuration."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$", var.rwx_self_hosted_runner_label))
    error_message = "The label may only contain letters, numbers, and dashes, and must start and end with a letter or number."
  }

  validation {
    condition     = length(var.rwx_self_hosted_runner_label) <= 63
    error_message = "The label must be 63 characters or fewer."
  }
}

variable "rwx_self_hosted_runner_external_id" {
  description = "External ID that RWX generates for this self-hosted runner configuration; look it up on cloud.rwx.com. The workload identity provider only accepts tokens RWX issues for this runner, and the names of the resources this module creates are derived from it."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.rwx_self_hosted_runner_external_id))
    error_message = "The external ID must be the 32 character hexadecimal value shown for this runner in RWX."
  }
}

variable "rwx_oidc_issuer" {
  description = "URL of the OIDC issuer that signs the tokens RWX presents to Google Cloud. Look it up on cloud.rwx.com."
  type        = string

  validation {
    condition     = can(regex("^https://", var.rwx_oidc_issuer))
    error_message = "The OIDC issuer must be an https URL."
  }
}

variable "project_id" {
  description = "ID of the Google Cloud project that runner instances launch in. Every resource this module creates lives in this project, except for the role that grants use of the subnetwork, which lives in the subnetwork's project."
  type        = string
}

variable "subnetwork" {
  description = "Full resource name of the subnetwork that RWX launches runner instances into, in the form `projects/PROJECT/regions/REGION/subnetworks/NAME`. The provisioning service account may use this subnetwork and no other. It may belong to a Shared VPC host project."
  type        = string

  validation {
    condition     = can(regex("^projects/[^/]+/regions/[^/]+/subnetworks/[^/]+$", var.subnetwork))
    error_message = "The subnetwork must be a full resource name in the form projects/PROJECT/regions/REGION/subnetworks/NAME."
  }
}
