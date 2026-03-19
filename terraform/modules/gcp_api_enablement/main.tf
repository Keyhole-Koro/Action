# Generic module to enable a set of GCP APIs

resource "google_project_service" "apis" {
  for_each = toset(var.required_apis)

  service            = each.key
  disable_on_destroy = false
}
