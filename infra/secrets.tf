# -----------------------------------------------------------------------------
# GCP Secret Manager — Application Secrets
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret" "app_secrets" {
  for_each = toset([
    "app-secret-key",
    "db-password",
    "redis-password",
  ])

  project   = var.project_id
  secret_id = each.key

  labels = local.common_labels

  replication {
    auto {}
  }
}

# -----------------------------------------------------------------------------
# Artifactory Secrets (conditional)
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret" "artifactory_access_token" {
  count     = var.create_artifactory_secrets ? 1 : 0
  project   = var.project_id
  secret_id = "artifactory-access-token"

  labels = local.common_labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "artifactory_username" {
  count     = var.create_artifactory_secrets ? 1 : 0
  project   = var.project_id
  secret_id = "artifactory-username"

  labels = local.common_labels

  replication {
    auto {}
  }
}

# -----------------------------------------------------------------------------
# Consul Secret (conditional)
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret" "consul_token" {
  count     = var.create_consul_secrets ? 1 : 0
  project   = var.project_id
  secret_id = "consul-token"

  labels = local.common_labels

  replication {
    auto {}
  }
}

# -----------------------------------------------------------------------------
# IAM — Grant CI/CD SA access to all secrets
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret_iam_member" "cicd_app_secrets" {
  for_each = google_secret_manager_secret.app_secrets

  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cicd.email}"
}

resource "google_secret_manager_secret_iam_member" "app_sa_secrets" {
  for_each = google_secret_manager_secret.app_secrets

  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.app.email}"
}