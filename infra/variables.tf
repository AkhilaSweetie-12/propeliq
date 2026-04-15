variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for zonal resources"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (e.g. production, staging)"
  type        = string
  default     = "production"
}

variable "app_name" {
  description = "Application name used for resource naming"
  type        = string
  default     = "propeliq"
}

# --- Networking ---

variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = "propeliq-vpc"
}

variable "subnet_cidr" {
  description = "Primary subnet CIDR range"
  type        = string
  default     = "10.0.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary range CIDR for GKE pods"
  type        = string
  default     = "10.4.0.0/14"
}

variable "services_cidr" {
  description = "Secondary range CIDR for GKE services"
  type        = string
  default     = "10.8.0.0/20"
}

variable "master_cidr" {
  description = "CIDR for GKE control plane (must be /28)"
  type        = string
  default     = "172.16.0.0/28"
}

# --- GKE ---

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "propeliq-cluster"
}

variable "gke_version" {
  description = "GKE release channel"
  type        = string
  default     = "REGULAR"
  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.gke_version)
    error_message = "Must be one of: RAPID, REGULAR, STABLE."
  }
}

variable "node_machine_type" {
  description = "Machine type for the default node pool"
  type        = string
  default     = "e2-standard-4"
}

variable "node_count" {
  description = "Initial number of nodes per zone"
  type        = number
  default     = 2
}

variable "node_min_count" {
  description = "Minimum nodes per zone for autoscaling"
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum nodes per zone for autoscaling"
  type        = number
  default     = 5
}

variable "node_disk_size_gb" {
  description = "Boot disk size in GB for nodes"
  type        = number
  default     = 100
}

variable "node_disk_type" {
  description = "Boot disk type for nodes"
  type        = string
  default     = "pd-standard"
}

variable "enable_private_nodes" {
  description = "Enable private nodes (no public IPs on nodes)"
  type        = bool
  default     = true
}

variable "master_authorized_networks" {
  description = "CIDR blocks authorized to access the GKE master"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

# --- Workload Identity ---

variable "github_org" {
  description = "GitHub organization or username for Workload Identity"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name for Workload Identity"
  type        = string
  default     = "propeliq"
}

# --- Secrets ---

variable "create_artifactory_secrets" {
  description = "Create Artifactory credential secrets in Secret Manager"
  type        = bool
  default     = false
}

variable "create_consul_secrets" {
  description = "Create Consul token secret in Secret Manager"
  type        = bool
  default     = false
}

# --- DNS / Load Balancer ---

variable "domain" {
  description = "Domain name for the application (e.g. app.example.com)"
  type        = string
  default     = ""
}

variable "enable_managed_certificate" {
  description = "Create a Google-managed SSL certificate"
  type        = bool
  default     = false
}

# --- Labels ---

variable "labels" {
  description = "Common labels applied to all resources"
  type        = map(string)
  default     = {}
}