# ==============================================================================
# Data Stores: Redis + GCS + Secret Manager
# ==============================================================================

# ──────────────────────────────────────────────
# Memorystore Redis
# ──────────────────────────────────────────────

resource "google_redis_instance" "main" {
  name           = "action-redis"
  tier           = "BASIC"
  memory_size_gb = var.redis_memory_size_gb
  region         = var.region

  authorized_network = "default"
  redis_version      = "REDIS_7_0"
  display_name       = "Action Redis"

  depends_on = [module.api_enablement.api_services]
}

# ──────────────────────────────────────────────
# GCS Bucket for Uploads
# ──────────────────────────────────────────────

resource "google_storage_bucket" "uploads" {
  name                        = "${var.organize_gcs_bucket}-${var.project_id}"
  location                    = var.region
  force_destroy               = false
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  # Allow browsers to PUT directly via presigned URLs.
  cors {
    origin          = var.act_api_cors_allowed_origins
    method          = ["PUT", "GET", "HEAD", "OPTIONS"]
    response_header = ["Content-Type", "ETag"]
    max_age_seconds = 3600
  }

  depends_on = [module.api_enablement.api_services]
}

# ──────────────────────────────────────────────
# Secret Manager
# ──────────────────────────────────────────────

resource "google_secret_manager_secret" "google_api_key" {
  secret_id = "google-api-key"

  replication {
    auto {}
  }

  depends_on = [module.api_enablement.api_services]
}

resource "google_secret_manager_secret_version" "google_api_key" {
  secret      = google_secret_manager_secret.google_api_key.id
  secret_data = var.google_api_key
}
