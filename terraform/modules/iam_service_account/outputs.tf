output "email" {
  description = "Service Account email"
  value       = google_service_account.sa.email
}

output "name" {
  description = "Service Account resource name"
  value       = google_service_account.sa.name
}
