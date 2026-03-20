# ==============================================================================
# IAM: Service Accounts + Workload Identity Federation
# ==============================================================================

# ──────────────────────────────────────────────
# Application Service Accounts (created via module)
# ──────────────────────────────────────────────

module "frontend_sa" {
  source       = "../modules/iam_service_account"
  project_id   = var.project_id
  account_id   = "frontend-sa"
  display_name = "Frontend Cloud Run SA"
}

module "act_api_sa" {
  source       = "../modules/iam_service_account"
  project_id   = var.project_id
  account_id   = "act-api-sa"
  display_name = "act-api Cloud Run SA"
}

module "act_adk_worker_sa" {
  source       = "../modules/iam_service_account"
  project_id   = var.project_id
  account_id   = "act-adk-worker-sa"
  display_name = "act-adk-worker Cloud Run SA"
}

module "organize_sa" {
  source       = "../modules/iam_service_account"
  project_id   = var.project_id
  account_id   = "organize-sa"
  display_name = "organize Cloud Run SA"
}

module "action_ingest_sa" {
  source       = "../modules/iam_service_account"
  project_id   = var.project_id
  account_id   = "action-ingest-sa"
  display_name = "action-ingest Cloud Run Job SA"
}

module "pubsub_invoker_sa" {
  source       = "../modules/iam_service_account"
  project_id   = var.project_id
  account_id   = "pubsub-invoker-sa"
  display_name = "Pub/Sub push invoker SA"
}

# ──────────────────────────────────────────────
# IAM Roles: Application Service Accounts
# ──────────────────────────────────────────────

# act-api roles
resource "google_project_iam_member" "act_api_firestore" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${module.act_api_sa.email}"
}

resource "google_project_iam_member" "act_api_storage" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${module.act_api_sa.email}"
}

resource "google_project_iam_member" "act_api_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${module.act_api_sa.email}"
}

resource "google_project_iam_member" "act_api_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${module.act_api_sa.email}"
}

# act-adk-worker roles
resource "google_project_iam_member" "adk_worker_firestore" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${module.act_adk_worker_sa.email}"
}

resource "google_project_iam_member" "adk_worker_storage" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${module.act_adk_worker_sa.email}"
}

resource "google_project_iam_member" "adk_worker_pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${module.act_adk_worker_sa.email}"
}

resource "google_project_iam_member" "adk_worker_aiplatform" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${module.act_adk_worker_sa.email}"
}

resource "google_project_iam_member" "adk_worker_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${module.act_adk_worker_sa.email}"
}

# organize roles
resource "google_project_iam_member" "organize_firestore" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${module.organize_sa.email}"
}

resource "google_project_iam_member" "organize_storage" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${module.organize_sa.email}"
}

resource "google_project_iam_member" "organize_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${module.organize_sa.email}"
}

resource "google_project_iam_member" "organize_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${module.organize_sa.email}"
}

resource "google_project_iam_member" "organize_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${module.organize_sa.email}"
}

resource "google_project_iam_member" "organize_aiplatform" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${module.organize_sa.email}"
}

resource "google_project_iam_member" "action_ingest_storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${module.action_ingest_sa.email}"
}

resource "google_project_iam_member" "action_ingest_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${module.action_ingest_sa.email}"
}

# ──────────────────────────────────────────────
# Workload Identity Federation: GitHub Actions
# ──────────────────────────────────────────────

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"

  depends_on = [module.api_enablement.api_services]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }
  attribute_condition = "assertion.repository == \"${var.github_repo}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# ──────────────────────────────────────────────
# CI/CD: GitHub deployer SA
# ──────────────────────────────────────────────

resource "google_service_account" "github_deployer" {
  account_id   = "github-deployer-sa"
  display_name = "GitHub Actions Deployer SA"
}

resource "google_service_account_iam_member" "github_deployer_wif" {
  service_account_id = google_service_account.github_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}

resource "google_project_iam_member" "deployer_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_project_iam_member" "deployer_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

# 状態保存バケットへのアクセス権限 (tfstate の読み書きに必要)
resource "google_storage_bucket_iam_member" "deployer_state_bucket_admin" {
  bucket = "action-490203-tfstate"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.github_deployer.email}"
}

# Deployer can impersonate application SAs
resource "google_service_account_iam_member" "deployer_impersonate_frontend" {
  service_account_id = module.frontend_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_service_account_iam_member" "deployer_impersonate_act_api" {
  service_account_id = module.act_api_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_service_account_iam_member" "deployer_impersonate_act_adk_worker" {
  service_account_id = module.act_adk_worker_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_service_account_iam_member" "deployer_impersonate_organize" {
  service_account_id = module.organize_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_service_account_iam_member" "deployer_impersonate_action_ingest" {
  service_account_id = module.action_ingest_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_deployer.email}"
}
