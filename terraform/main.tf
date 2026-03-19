# ==============================================================================
# Root Module: Orchestrate infrastructure
# ==============================================================================

module "infrastructure" {
  source = "./infrastructure"

  project_id                   = var.project_id
  region                       = var.region
  image_tag                    = var.image_tag
  github_repo                  = var.github_repo
  redis_memory_size_gb         = var.redis_memory_size_gb
  gemini_model_fast            = var.gemini_model_fast
  gemini_model_quality         = var.gemini_model_quality
  organize_gcs_bucket          = var.organize_gcs_bucket
  act_api_cors_allowed_origins = var.act_api_cors_allowed_origins
  firebase_api_key             = var.firebase_api_key
  firebase_auth_domain         = var.firebase_auth_domain
  firebase_app_id              = var.firebase_app_id
  action_ingest_workspace_id   = var.action_ingest_workspace_id
}
