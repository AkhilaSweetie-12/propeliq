# -----------------------------------------------------------------------------
# GKE Cluster
# -----------------------------------------------------------------------------

output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_zone" {
  description = "GKE cluster zone"
  value       = google_container_cluster.primary.location
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate (base64)"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

output "network_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "network_id" {
  description = "VPC network self link"
  value       = google_compute_network.vpc.id
}

output "subnet_name" {
  description = "Node subnet name"
  value       = google_compute_subnetwork.nodes.name
}

output "ingress_ip" {
  description = "Global static IP for ingress"
  value       = google_compute_global_address.ingress.address
}

# -----------------------------------------------------------------------------
# Service Accounts
# -----------------------------------------------------------------------------

output "cicd_service_account_email" {
  description = "CI/CD service account email (for GitHub Actions)"
  value       = google_service_account.cicd.email
}

output "app_service_account_email" {
  description = "Application service account email (for GKE pods)"
  value       = google_service_account.app.email
}

# -----------------------------------------------------------------------------
# Workload Identity Federation
# -----------------------------------------------------------------------------

output "workload_identity_provider" {
  description = "Full resource name of the Workload Identity Provider (set as GCP_WORKLOAD_IDENTITY_PROVIDER secret)"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "workload_identity_pool" {
  description = "Workload Identity Pool ID"
  value       = google_iam_workload_identity_pool.github.workload_identity_pool_id
}

# -----------------------------------------------------------------------------
# Secrets
# -----------------------------------------------------------------------------

output "secret_ids" {
  description = "Map of Secret Manager secret names to their IDs"
  value = {
    for k, v in google_secret_manager_secret.app_secrets : k => v.secret_id
  }
}

# -----------------------------------------------------------------------------
# Cloud Armor
# -----------------------------------------------------------------------------

output "security_policy_name" {
  description = "Cloud Armor security policy name"
  value       = google_compute_security_policy.app.name
}

# -----------------------------------------------------------------------------
# GitHub Actions Configuration
# -----------------------------------------------------------------------------

output "github_actions_config" {
  description = "Values to set as GitHub repository secrets and variables"
  value = {
    secrets = {
      GCP_WORKLOAD_IDENTITY_PROVIDER = google_iam_workload_identity_pool_provider.github.name
      GCP_SERVICE_ACCOUNT            = google_service_account.cicd.email
    }
    variables = {
      GCP_PROJECT_ID   = var.project_id
      GKE_CLUSTER_NAME = google_container_cluster.primary.name
      GKE_CLUSTER_ZONE = google_container_cluster.primary.location
      HEALTH_ENDPOINT  = var.domain != "" ? "https://${var.domain}/health" : "http://${google_compute_global_address.ingress.address}/health"
    }
  }
}