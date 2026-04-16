resource "google_service_account" "runtime" {
  account_id   = "${var.environment}-${var.service_account_name}"
  display_name = "Runtime service account for ${var.environment}"
}

resource "google_secret_manager_secret" "app_config" {
  secret_id = "${var.environment}-app-config"

  replication {
    auto {}
  }
}
