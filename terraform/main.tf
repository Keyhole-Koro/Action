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
  google_api_key               = var.google_api_key
  discord_bot_token            = var.discord_bot_token
  discord_application_id       = var.discord_application_id
  firebase_auth_domain         = var.firebase_auth_domain
  firebase_app_id              = var.firebase_app_id
  action_ingest_workspace_id   = var.action_ingest_workspace_id
  discord_bot_zone             = var.discord_bot_zone
  discord_bot_machine_type     = var.discord_bot_machine_type
}
