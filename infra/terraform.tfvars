# Development Environment Configuration for PropelIQ GCP Infrastructure

gcp_project_id = "akhila-gcp-123-493309"
gcp_region     = "us-central1"
environment    = "dev"

# Cluster Configuration
cluster_name = "propeliq-gke"

# Network Configuration
vpc_network_name = "propeliq-vpc"
subnet_name      = "propeliq-subnet"
subnet_cidr      = "10.0.0.0/20"
pods_cidr        = "10.4.0.0/14"
services_cidr    = "10.8.0.0/20"

# Node Pool Configuration
node_pool_name = "primary-nodes"  # Changed from default-pool to avoid conflict with GKE's auto-created pool
node_count     = 1  # Reduced from 3 to 1 for dev cost/quota optimization
machine_type   = "e2-medium"  # Cost-effective for dev
disk_size_gb   = 30  # Reduced from 50 to stay within SSD quota limits

# Add-ons and Features
enable_logging   = true
enable_monitoring = true
add_cluster_firewall_rules = true

# Kubernetes Namespace
kubernetes_namespace = "default"

# Labels
labels = {
  project     = "propeliq"
  environment = "dev"
  managed_by  = "terraform"
  team        = "platform"
}
