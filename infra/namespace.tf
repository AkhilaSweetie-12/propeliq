# -----------------------------------------------------------------------------
# Kubernetes Namespaces
# -----------------------------------------------------------------------------

resource "kubernetes_namespace" "production" {
  metadata {
    name = "production"

    labels = {
      app         = var.app_name
      environment = "production"
      managed_by  = "terraform"
    }

    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.app.email
    }
  }

  depends_on = [google_container_node_pool.primary_nodes]
}

resource "kubernetes_namespace" "staging" {
  metadata {
    name = "staging"

    labels = {
      app         = var.app_name
      environment = "staging"
      managed_by  = "terraform"
    }
  }

  depends_on = [google_container_node_pool.primary_nodes]
}

# -----------------------------------------------------------------------------
# Resource Quotas
# -----------------------------------------------------------------------------

resource "kubernetes_resource_quota" "production" {
  metadata {
    name      = "production-quota"
    namespace = kubernetes_namespace.production.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = "8"
      "requests.memory" = "16Gi"
      "limits.cpu"      = "16"
      "limits.memory"   = "32Gi"
      "pods"            = "50"
      "services"        = "20"
    }
  }
}

resource "kubernetes_resource_quota" "staging" {
  metadata {
    name      = "staging-quota"
    namespace = kubernetes_namespace.staging.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = "4"
      "requests.memory" = "8Gi"
      "limits.cpu"      = "8"
      "limits.memory"   = "16Gi"
      "pods"            = "30"
      "services"        = "10"
    }
  }
}

# -----------------------------------------------------------------------------
# Limit Ranges
# -----------------------------------------------------------------------------

resource "kubernetes_limit_range" "production" {
  metadata {
    name      = "production-limits"
    namespace = kubernetes_namespace.production.metadata[0].name
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "500m"
        memory = "512Mi"
      }
      default_request = {
        cpu    = "100m"
        memory = "128Mi"
      }
      max = {
        cpu    = "4"
        memory = "8Gi"
      }
    }
  }
}

resource "kubernetes_limit_range" "staging" {
  metadata {
    name      = "staging-limits"
    namespace = kubernetes_namespace.staging.metadata[0].name
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "250m"
        memory = "256Mi"
      }
      default_request = {
        cpu    = "50m"
        memory = "64Mi"
      }
      max = {
        cpu    = "2"
        memory = "4Gi"
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Kubernetes Service Account (Workload Identity binding)
# -----------------------------------------------------------------------------

resource "kubernetes_service_account" "app" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.production.metadata[0].name

    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.app.email
    }

    labels = {
      app        = var.app_name
      managed_by = "terraform"
    }
  }
}