locals {
  gke_location = var.environment == "dev" ? "${var.gcp_region}-a" : var.gcp_region
  gke_location_flag = var.environment == "dev" ? "--zone" : "--region"
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = local.gke_location
  project  = var.gcp_project_id

  # Do not manage node pool here - use separate resource
  remove_default_node_pool = true
  initial_node_count       = 1

  # GKE still creates a temporary default pool during bootstrap.
  # Keep it as small and cheap as possible before it is removed.
  node_config {
    machine_type = var.machine_type
    disk_size_gb = 10
    disk_type    = "pd-standard"
  }

  # Network configuration
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  # Protection setting - disabled for dev for easier management
  deletion_protection = var.environment == "prod" ? true : false

  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # GKE add-ons (deprecated config removed, using stable fields)
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    cloudrun_config {
      disabled = true
    }
    dns_cache_config {
      enabled = true
    }
  }

  # Logging and monitoring - using modern API
  logging_service    = var.enable_logging ? "logging.googleapis.com/kubernetes" : "none"
  monitoring_service = var.enable_monitoring ? "monitoring.googleapis.com/kubernetes" : "none"

  # Network policy for security
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  # Cluster autoscaling
  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "cpu"
      minimum       = 1
      maximum       = 64
    }
    resource_limits {
      resource_type = "memory"
      minimum       = 1
      maximum       = 256
    }
  }

  # Security configuration
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Release channel for automatic updates
  release_channel {
    channel = var.environment == "prod" ? "REGULAR" : "RAPID"
  }

  # Required when node pools use workload_metadata_config.mode = "GKE_METADATA"
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }


  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  resource_labels = var.labels

  depends_on = [
    google_compute_network.vpc,
    google_compute_subnetwork.subnet
  ]
}

# Default Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name           = var.node_pool_name
  location       = local.gke_location
  cluster        = google_container_cluster.primary.name
  node_count     = var.node_count
  project        = var.gcp_project_id

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = var.environment == "dev" ? true : false
    machine_type = var.machine_type
    service_account = var.node_service_account

    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-standard"

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = var.labels

    tags = ["${var.cluster_name}-node"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  autoscaling {
    min_node_count = var.environment == "dev" ? 1 : 3
    max_node_count = 10
  }

  depends_on = [google_container_cluster.primary]
}

# Optional: Additional node pool for workloads
resource "google_container_node_pool" "workload_pool" {
  count          = var.environment == "prod" ? 1 : 0
  name           = "workload-pool"
  location       = local.gke_location
  cluster        = google_container_cluster.primary.name
  node_count     = 2
  project        = var.gcp_project_id

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = false
    machine_type = "e2-standard-2"
    disk_size_gb = 100
    service_account = var.node_service_account

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append"
    ]

    labels = merge(var.labels, {
      pool = "workload"
    })

    tags = ["${var.cluster_name}-workload"]


    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  autoscaling {
    min_node_count = 2
    max_node_count = 20
  }

  depends_on = [google_container_cluster.primary]
}
