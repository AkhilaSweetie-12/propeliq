gcp_project_id = "akhila-gcp-123-493309"
gcp_region     = "us-central1"
environment    = "prod"

cluster_name = "propeliq-gke-prod"

vpc_network_name = "propeliq-vpc-prod"
subnet_name      = "propeliq-subnet-prod"
subnet_cidr      = "10.40.0.0/20"
pods_cidr        = "10.44.0.0/14"
services_cidr    = "10.48.0.0/20"

node_pool_name       = "prod-pool"
node_count           = 3
machine_type         = "e2-standard-4"
node_service_account = "default"
disk_size_gb         = 100

enable_logging             = true
enable_monitoring          = true
add_cluster_firewall_rules = true

kubernetes_namespace = "prod"

labels = {
  project     = "propeliq"
  environment = "prod"
  managed_by  = "terraform"
  team        = "platform"
}
