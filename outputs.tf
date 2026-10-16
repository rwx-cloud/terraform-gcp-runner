output "workload_identity_provider" {
  description = "Full resource name of the workload identity provider RWX authenticates through."
  value       = google_iam_workload_identity_pool_provider.rwx.name
}

output "provisioning_service_account_email" {
  description = "Email of the service account RWX impersonates to manage runners in this project."
  value       = google_service_account.provisioning.email
}

output "instance_service_account_email" {
  description = "Email of the service account that runner instances run as. Grant it roles to give your builds access to other Google Cloud resources."
  value       = google_service_account.runner.email
}
