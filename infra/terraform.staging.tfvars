gcp_project_id = "akhila-gcp-123-493309"
gcp_region     = "us-central1"
environment    = "staging"

cluster_name = "propeliq-gke-staging"

vpc_network_name = "propeliq-vpc-staging"
subnet_name      = "propeliq-subnet-staging"
subnet_cidr      = "10.20.0.0/20"
pods_cidr        = "10.24.0.0/14"
services_cidr    = "10.28.0.0/20"

node_pool_name       = "staging-pool"
node_count           = 2
machine_type         = "e2-standard-2"
node_service_account = "default"
disk_size_gb         = 80

enable_logging             = true
enable_monitoring          = true
add_cluster_firewall_rules = true

kubernetes_namespace = "staging"

labels = {
  project     = "propeliq"
  environment = "staging"
  managed_by  = "terraform"
  team        = "platform"
}
