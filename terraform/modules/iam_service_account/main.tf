# Generic module to create a Service Account

resource "google_service_account" "sa" {
  account_id   = var.account_id
  display_name = var.display_name
}
