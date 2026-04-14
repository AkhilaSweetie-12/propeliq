output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE Cluster Host/Endpoint"
  sensitive   = true
}

output "kubernetes_cluster_ca_certificate" {
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  description = "Cluster CA Certificate"
  sensitive   = true
}

output "region" {
  value       = var.gcp_region
  description = "GCP Region"
}

output "project_id" {
  value       = var.gcp_project_id
  description = "GCP Project ID"
}

output "vpc_network_id" {
  value       = google_compute_network.vpc.id
  description = "VPC Network ID"
}

output "vpc_network_name" {
  value       = google_compute_network.vpc.name
  description = "VPC Network Name"
}

output "subnet_id" {
  value       = google_compute_subnetwork.subnet.id
  description = "Subnet ID"
}

output "subnet_name" {
  value       = google_compute_subnetwork.subnet.name
  description = "Subnet Name"
}

output "router_name" {
  value       = google_compute_router.router.name
  description = "Cloud Router Name"
}

output "nat_name" {
  value       = google_compute_router_nat.nat.name
  description = "Cloud NAT Name"
}

output "node_pool_name" {
  value       = google_container_node_pool.primary_nodes.name
  description = "Default Node Pool Name"
}

output "get_gke_credentials_command" {
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} ${local.gke_location_flag} ${local.gke_location} --project ${var.gcp_project_id}"
  description = "Command to configure kubectl"
}

output "kubeconfig_context" {
  value       = "gke_${var.gcp_project_id}_${local.gke_location}_${google_container_cluster.primary.name}"
  description = "Kubectl context name"
}
