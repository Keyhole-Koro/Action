# ==============================================================================
# Core Infrastructure: API Enablement + Artifact Registry
# ==============================================================================

module "api_enablement" {
  source = "../modules/gcp_api_enablement"
}

# Artifact Registry Repository (shared by all services)
resource "google_artifact_registry_repository" "action" {
  location      = var.region
  repository_id = "action"
  format        = "DOCKER"

  depends_on = [module.api_enablement.api_services]
}
