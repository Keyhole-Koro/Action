# ==============================================================================
# Root Module Outputs (pass-through from infrastructure module)
# ==============================================================================

output "frontend_url" {
  description = "Frontend Cloud Run service URL"
  value       = module.infrastructure.frontend_url
}

output "act_api_url" {
  description = "act-api Cloud Run service URL"
  value       = module.infrastructure.act_api_url
}

output "act_adk_worker_url" {
  description = "act-adk-worker Cloud Run service URL"
  value       = module.infrastructure.act_adk_worker_url
}

output "organize_url" {
  description = "organize Cloud Run service URL"
  value       = module.infrastructure.organize_url
}

output "action_ingest_job_name" {
  description = "action-ingest Cloud Run Job name"
  value       = module.infrastructure.action_ingest_job_name
}

output "redis_host" {
  description = "Memorystore Redis host"
  value       = module.infrastructure.redis_host
}

output "uploads_bucket" {
  description = "GCS uploads bucket name"
  value       = module.infrastructure.uploads_bucket
}

output "workload_identity_provider" {
  description = "WIF Provider for GitHub Actions (→ GitHub Secret: WIF_PROVIDER)"
  value       = module.infrastructure.workload_identity_provider
}

output "github_deployer_sa" {
  description = "GitHub deployer Service Account email (→ GitHub Secret: GCP_DEPLOYER_SA)"
  value       = module.infrastructure.github_deployer_sa
}

output "service_accounts" {
  description = "All service account emails"
  value       = module.infrastructure.service_accounts
}
