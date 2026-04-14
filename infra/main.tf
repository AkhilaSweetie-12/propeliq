# PropelIQ Infrastructure as Code - GCP GKE Cluster
# This is the main entry point for infrastructure configuration
# Supports Dev environment with Kubernetes-based microservices

locals {
  cluster_id = "${var.cluster_name}-${var.environment}"
  common_labels = merge(
    var.labels,
    {
      cluster_version = "1.0"
      created_at      = timestamp()
    }
  )
}

# Resource naming convention: {project}-{environment}-{resource_type}-{identifier}
# Example: propeliq-dev-gke-cluster, propeliq-dev-vpc

# All cloud resources are defined in separate Terraform files:
# - providers.tf: Provider configuration
# - variables.tf: Input variables
# - networking.tf: VPC, subnets, routing, firewalls
# - gke.tf: GKE cluster and node pools
# - outputs.tf: Output values
