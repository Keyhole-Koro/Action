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

  project_id                = var.project_id
  region                    = var.region
  service_name              = "frontend"
  image_uri                 = "${local.image_base}/frontend:${var.image_tag}"
  service_account_email     = module.frontend_sa.email
  container_port            = 3000
  cpu_limit                 = "1"
  memory_limit              = "512Mi"
  startup_cpu_boost         = true
  allow_public              = true
  min_instances             = 0
  max_instances             = 3

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

  project_id                = var.project_id
  region                    = var.region
  service_name              = "act-api"
  image_uri                 = "${local.image_base}/act-api:${var.image_tag}"
  service_account_email     = module.act_api_sa.email
  container_port            = 8080
  cpu_limit                 = "2"
  memory_limit              = "1Gi"
  startup_cpu_boost         = true
  allow_public              = false
  min_instances             = 1
  max_instances             = 5
  vpc_connector_id          = google_vpc_access_connector.redis_connector.id
  ingress                   = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  environment_variables = {
    REDIS_ADDR               = "${google_redis_instance.main.host}:6379"
    REDIS_DB                 = "0"
    CORS_ALLOWED_ORIGINS     = join(",", var.act_api_cors_allowed_origins)
    ACT_ADK_WORKER_URL       = module.act_adk_worker_service.uri
    GOOGLE_CLOUD_PROJECT     = var.project_id
    GCS_BUCKET               = google_storage_bucket.uploads.name
    SID_STRICT               = "false"
    SID_TTL_SECONDS          = "86400"
    CSRF_TTL_SECONDS         = "3600"
    SID_REQ_TTL_SECONDS      = "300"
    SID_LOCK_TTL_SECONDS     = "60"
    GOOGLE_API_KEY           = var.firebase_api_key
    GOOGLE_API_KEY_SECRET_ID = google_secret_manager_secret.google_api_key.secret_id
    GEMINI_MODEL             = var.gemini_model_quality
  }

  depends_on = [module.api_enablement.api_services]
}

# ──────────────────────────────────────────────
# act-adk-worker
# ──────────────────────────────────────────────

module "act_adk_worker_service" {
  source = "../modules/cloud_run_service"

  project_id                = var.project_id
  region                    = var.region
  service_name              = "act-adk-worker"
  image_uri                 = "${local.image_base}/act-adk-worker:${var.image_tag}"
  service_account_email     = module.act_adk_worker_sa.email
  container_port            = 8080
  cpu_limit                 = "4"
  memory_limit              = "2Gi"
  startup_cpu_boost         = true
  allow_public              = false
  min_instances             = 1
  max_instances             = 10
  vpc_connector_id          = google_vpc_access_connector.redis_connector.id
  ingress                   = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  environment_variables = {
    REDIS_ADDR           = "${google_redis_instance.main.host}:6379"
    GCS_BUCKET_NAME      = google_storage_bucket.uploads.name
    PUBSUB_TOPIC_NAME    = google_pubsub_topic.mind_events.name
    GEMINI_MODEL         = var.gemini_model_fast
    GOOGLE_API_KEY       = var.firebase_api_key
    GOOGLE_CLOUD_PROJECT = var.project_id
  }

  depends_on = [module.api_enablement.api_services]
}

# ──────────────────────────────────────────────
# organize
# ──────────────────────────────────────────────

module "organize_service" {
  source = "../modules/cloud_run_service"

  project_id                = var.project_id
  region                    = var.region
  service_name              = "organize"
  image_uri                 = "${local.image_base}/organize:${var.image_tag}"
  service_account_email     = module.organize_sa.email
  container_port            = 8080
  cpu_limit                 = "4"
  memory_limit              = "2Gi"
  startup_cpu_boost         = true
  allow_public              = false
  min_instances             = 1
  max_instances             = 5
  vpc_connector_id          = google_vpc_access_connector.redis_connector.id
  ingress                   = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  environment_variables = {
    NODE_ENV               = "production"
    STATE_BACKEND          = "firestore"
    GOOGLE_CLOUD_PROJECT   = var.project_id
    PUBSUB_TOPIC_NAME      = google_pubsub_topic.mind_events.name
    PUBSUB_PUBLISH_ENABLED = "true"
    ORGANIZE_GCS_BUCKET    = google_storage_bucket.uploads.name
    LEASE_TTL_SECONDS      = "301"
    GOOGLE_API_KEY         = var.firebase_api_key
    GEMINI_MODEL_FAST      = var.gemini_model_fast
    GEMINI_MODEL_QUALITY   = var.gemini_model_quality
    REDIS_HOST             = google_redis_instance.main.host
    REDIS_ADDR             = "${google_redis_instance.main.host}:6379"
  }

  depends_on = [module.api_enablement.api_services]
}
