# VPC Network
resource "google_compute_network" "vpc" {
  name                    = var.vpc_network_name
  auto_create_subnetworks = false
  project                 = var.gcp_project_id
  routing_mode            = "REGIONAL"

  depends_on = []
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.vpc.id
  project       = var.gcp_project_id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }

  depends_on = [google_compute_network.vpc]
}

# Cloud Router for NAT
resource "google_compute_router" "router" {
  name    = "${var.cluster_name}-router"
  region  = var.gcp_region
  network = google_compute_network.vpc.id
  project = var.gcp_project_id
}

# Cloud NAT for outbound connectivity
resource "google_compute_router_nat" "nat" {
  name                               = "${var.cluster_name}-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = var.enable_logging
    filter = "ERRORS_ONLY"
  }

  depends_on = [google_compute_router.router]
}

# Firewall - Allow internal communication
resource "google_compute_firewall" "internal" {
  count   = var.add_cluster_firewall_rules ? 1 : 0
  name    = "${var.cluster_name}-allow-internal"
  network = google_compute_network.vpc.name
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr]

  depends_on = [google_compute_network.vpc]
}

# Firewall - Allow SSH from bastion/admin
resource "google_compute_firewall" "ssh" {
  count   = var.add_cluster_firewall_rules ? 1 : 0
  name    = "${var.cluster_name}-allow-ssh"
  network = google_compute_network.vpc.name
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Allow SSH only via Google IAP TCP forwarding range instead of public internet.
  source_ranges = ["35.235.240.0/20"]

  depends_on = [google_compute_network.vpc]
}
