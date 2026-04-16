output "runtime_service_account" {
  value = google_service_account.runtime.email
}

output "secret_name" {
  value = google_secret_manager_secret.app_config.secret_id
}
