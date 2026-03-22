# ==============================================================================
# Cloud Run Services
# ==============================================================================

locals {
  image_base = "${var.region}-docker.pkg.dev/${var.project_id}/action"
}

# ──────────────────────────────────────────────
# Frontend
# ──────────────────────────────────────────────

module "frontend_service" {
  source = "../modules/cloud_run_service"

  project_id            = var.project_id
  region                = var.region
  service_name          = "frontend"
  image_uri             = "${local.image_base}/frontend:${var.image_tag}"
  service_account_email = module.frontend_sa.email
  container_port        = 3000
  cpu_limit             = "1"
  memory_limit          = "512Mi"
  startup_cpu_boost     = true
  allow_public          = true
  min_instances         = 0
  max_instances         = 3

  environment_variables = {
    NEXT_PUBLIC_USE_MOCKS            = "false"
    NEXT_PUBLIC_RPC_BASE_URL         = module.act_api_service.uri
    NEXT_PUBLIC_ACT_API_BASE_URL     = module.act_api_service.uri
    NEXT_PUBLIC_FIREBASE_API_KEY     = var.firebase_api_key
    NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN = var.firebase_auth_domain
    NEXT_PUBLIC_FIREBASE_APP_ID      = var.firebase_app_id
    NEXT_PUBLIC_GCLOUD_PROJECT       = var.project_id
  }

  depends_on = [module.api_enablement.api_services]
}

# ──────────────────────────────────────────────
# act-api
# ──────────────────────────────────────────────

module "act_api_service" {
  source = "../modules/cloud_run_service"

  project_id            = var.project_id
  region                = var.region
  service_name          = "act-api"
  image_uri             = "${local.image_base}/act-api:${var.image_tag}"
  service_account_email = module.act_api_sa.email
  container_port        = 8080
  cpu_limit             = "1"
  memory_limit          = "512Mi"
  startup_cpu_boost     = true
  allow_public          = true
  min_instances         = 0
  max_instances         = 5
  vpc_connector_id      = google_vpc_access_connector.redis_connector.id
  ingress               = "INGRESS_TRAFFIC_ALL"

  environment_variables = {
    REDIS_ADDR             = "${google_redis_instance.main.host}:6379"
    REDIS_DB               = "0"
    CORS_ALLOWED_ORIGINS   = join(",", var.act_api_cors_allowed_origins)
    ACT_ADK_WORKER_URL     = module.act_adk_worker_service.uri
    GOOGLE_CLOUD_PROJECT   = var.project_id
    GCS_BUCKET             = google_storage_bucket.uploads.name
    DISCORD_APPLICATION_ID = var.discord_application_id
    SID_STRICT             = "false"
    SID_TTL_SECONDS        = "86400"
    CSRF_TTL_SECONDS       = "3600"
    SID_REQ_TTL_SECONDS    = "300"
    SID_LOCK_TTL_SECONDS   = "60"
    GEMINI_MODEL           = var.gemini_model_quality
  }

  depends_on = [module.api_enablement.api_services]
}

# ──────────────────────────────────────────────
# act-adk-worker
# ──────────────────────────────────────────────

module "act_adk_worker_service" {
  source = "../modules/cloud_run_service"

  project_id            = var.project_id
  region                = var.region
  service_name          = "act-adk-worker"
  image_uri             = "${local.image_base}/act-adk-worker:${var.image_tag}"
  service_account_email = module.act_adk_worker_sa.email
  container_port        = 8080
  cpu_limit             = "1"
  memory_limit          = "1Gi"
  startup_cpu_boost     = true
  allow_public          = false
  min_instances         = 0
  max_instances         = 10
  vpc_connector_id      = google_vpc_access_connector.redis_connector.id
  ingress               = "INGRESS_TRAFFIC_ALL"
  allowed_invokers      = [module.act_api_sa.email]

  environment_variables = {
    REDIS_ADDR           = "${google_redis_instance.main.host}:6379"
    GCS_BUCKET_NAME      = google_storage_bucket.uploads.name
    PUBSUB_TOPIC_NAME    = google_pubsub_topic.mind_events.name
    GEMINI_MODEL         = var.gemini_model_fast
    GOOGLE_CLOUD_PROJECT = var.project_id
  }

  secret_environment_variables = {
    GOOGLE_API_KEY = {
      secret  = google_secret_manager_secret.google_api_key.secret_id
      version = "latest"
    }
  }

  depends_on = [module.api_enablement.api_services]
}

# ──────────────────────────────────────────────
# organize
# ──────────────────────────────────────────────

module "organize_service" {
  source = "../modules/cloud_run_service"

  project_id            = var.project_id
  region                = var.region
  service_name          = "organize"
  image_uri             = "${local.image_base}/organize:${var.image_tag}"
  service_account_email = module.organize_sa.email
  container_port        = 8090
  container_concurrency = 1
  cpu_limit             = "1"
  memory_limit          = "2Gi"
  startup_cpu_boost     = true
  allow_public          = false
  allowed_invokers      = [module.pubsub_invoker_sa.email]
  min_instances         = 0
  max_instances         = 5
  vpc_connector_id      = google_vpc_access_connector.redis_connector.id
  ingress               = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  environment_variables = {
    NODE_ENV                    = "production"
    STATE_BACKEND               = "firestore"
    GOOGLE_CLOUD_PROJECT        = var.project_id
    PUBSUB_TOPIC_NAME           = google_pubsub_topic.mind_events.name
    PUBSUB_PUBLISH_ENABLED      = "true"
    ORGANIZE_GCS_BUCKET         = google_storage_bucket.uploads.name
    LEASE_TTL_SECONDS           = "301"
    GEMINI_MODEL_FAST           = var.gemini_model_fast
    GEMINI_MODEL_QUALITY        = var.gemini_model_quality
    REDIS_HOST                  = google_redis_instance.main.host
    REDIS_ADDR                  = "${google_redis_instance.main.host}:6379"
    LLM_LIMITER_REDIS_URL       = "redis://${google_redis_instance.main.host}:6379"
    LLM_LIMITER_TARGET_TPM      = "1200000"
    LLM_LIMITER_TARGET_RPM      = "10000"
    LLM_LIMITER_MAX_CONCURRENCY = "50"
  }

  secret_environment_variables = {
    GOOGLE_API_KEY = {
      secret  = google_secret_manager_secret.google_api_key.secret_id
      version = "latest"
    }
  }

  depends_on = [module.api_enablement.api_services]
}

# ──────────────────────────────────────────────
# action-ingest job
# ──────────────────────────────────────────────

resource "google_cloud_run_v2_job" "action_ingest_job" {
  name     = "action-ingest"
  location = var.region
  project  = var.project_id

  template {
    template {
      service_account = module.action_ingest_sa.email
      timeout         = "3600s"
      max_retries     = 1

      containers {
        image = "${local.image_base}/action-ingest:${var.image_tag}"

        env {
          name  = "INGEST_WORKSPACE_ID"
          value = var.action_ingest_workspace_id
        }

        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = var.project_id
        }

        env {
          name  = "PUBSUB_TOPIC_NAME"
          value = google_pubsub_topic.mind_events.name
        }

        env {
          name  = "PUBSUB_MODE"
          value = "gcp"
        }

        env {
          name  = "INGEST_TARGET_CHUNK_TOKENS"
          value = "6000"
        }

        env {
          name  = "INGEST_RESERVED_OUTPUT_TOKENS"
          value = "512"
        }

        env {
          name  = "INGEST_PRIORITY"
          value = "normal"
        }

        env {
          name  = "INGEST_TOPIC_PREFIX"
          value = "topic:ingest"
        }

        env {
          name  = "INGEST_ASSET_BUCKET"
          value = google_storage_bucket.uploads.name
        }
      }
    }
  }

  deletion_protection = false

  depends_on = [module.api_enablement.api_services]
}
