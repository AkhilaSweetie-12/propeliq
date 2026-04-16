variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "region" {
  description = "Primary region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "staging", "prod"], var.environment)
    error_message = "Environment must be one of dev, qa, staging, prod."
  }
}

variable "vpc_cidr" {
  description = "Primary subnet CIDR"
  type        = string
}

variable "service_account_name" {
  description = "Service account id"
  type        = string
  default     = "platform-runtime"
}
