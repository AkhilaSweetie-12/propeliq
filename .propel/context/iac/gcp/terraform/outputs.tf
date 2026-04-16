output "network_name" {
  value       = module.networking.network_name
  description = "Provisioned VPC name"
}

output "runtime_service_account" {
  value       = module.security.runtime_service_account
  description = "Runtime service account email"
}
