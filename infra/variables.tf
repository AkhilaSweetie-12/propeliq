variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]{4,28}[a-z0-9])$", var.gcp_project_id))
    error_message = "Project ID must be between 6-30 characters."
  }
}

variable "gcp_region" {
  description = "GCP Region for resources"
  type        = string
  default     = "us-central1"
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+\\d$", var.gcp_region))
    error_message = "Must be a valid GCP region (e.g., us-central1)."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be 'dev', 'staging', or 'prod'."
  }
}

variable "cluster_name" {
  description = "GKE Cluster name"
  type        = string
  default     = "propeliq-gke"
}

variable "vpc_network_name" {
  description = "VPC network name"
  type        = string
  default     = "propeliq-vpc"
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
  default     = "propeliq-subnet"
}

variable "subnet_cidr" {
  description = "Subnet CIDR block"
  type        = string
  default     = "10.0.0.0/20"
}

variable "pods_cidr" {
  description = "Pod CIDR block for GKE"
  type        = string
  default     = "10.4.0.0/14"
}

variable "services_cidr" {
  description = "Services CIDR block for GKE"
  type        = string
  default     = "10.8.0.0/20"
}

variable "node_pool_name" {
  description = "Default node pool name"
  type        = string
  default     = "default-pool"
}

variable "node_count" {
  description = "Number of nodes in default pool"
  type        = number
  default     = 3
  validation {
    condition     = var.node_count >= 1 && var.node_count <= 10
    error_message = "Node count must be between 1 and 10."
  }
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
  validation {
    condition     = can(regex("^(e2|n1|n2|t2d)-(micro|small|medium|standard|highmem|highcpu)", var.machine_type))
    error_message = "Must be a valid GCP machine type."
  }
}

variable "node_service_account" {
  description = "Service account email used by GKE nodes"
  type        = string
  default     = "default"
}

variable "disk_size_gb" {
  description = "Disk size for nodes in GB"
  type        = number
  default     = 50
  validation {
    condition     = var.disk_size_gb >= 20 && var.disk_size_gb <= 2000
    error_message = "Disk size must be between 20 and 2000 GB."
  }
}

variable "enable_logging" {
  description = "Enable GKE logging"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable GKE monitoring"
  type        = bool
  default     = true
}

variable "add_cluster_firewall_rules" {
  description = "Create firewall rules for cluster"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default = {
    project     = "propeliq"
    managed_by  = "terraform"
    environment = "dev"
  }
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for applications"
  type        = string
  default     = "default"
}
