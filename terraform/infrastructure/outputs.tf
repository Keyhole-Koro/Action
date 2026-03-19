# Infrastructure layer outputs for root module

output "frontend_url" {
  description = "Frontend Cloud Run service URL"
  value       = module.frontend_service.uri
}

output "act_api_url" {
  description = "act-api Cloud Run service URL"
  value       = module.act_api_service.uri
}

output "act_adk_worker_url" {
  description = "act-adk-worker Cloud Run service URL"
  value       = module.act_adk_worker_service.uri
}

output "organize_url" {
  description = "organize Cloud Run service URL"
  value       = module.organize_service.uri
}

output "action_ingest_job_name" {
  description = "action-ingest Cloud Run Job name"
  value       = google_cloud_run_v2_job.action_ingest_job.name
}

output "redis_host" {
  description = "Memorystore Redis host"
  value       = google_redis_instance.main.host
}

output "uploads_bucket" {
  description = "GCS uploads bucket name"
  value       = google_storage_bucket.uploads.name
}

output "workload_identity_provider" {
  description = "WIF Provider for GitHub Actions → use in GitHub Secrets"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "github_deployer_sa" {
  description = "GitHub deployer Service Account email → use in GitHub Secrets"
  value       = google_service_account.github_deployer.email
}

output "service_accounts" {
  description = "Service account emails"
  value = {
    frontend       = module.frontend_sa.email
    act_api        = module.act_api_sa.email
    act_adk_worker = module.act_adk_worker_sa.email
    organize       = module.organize_sa.email
    action_ingest  = module.action_ingest_sa.email
    pubsub_invoker = module.pubsub_invoker_sa.email
  }
}
