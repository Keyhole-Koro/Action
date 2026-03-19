#!/bin/bash
# scripts/terraform-import.sh

set -e

PROJECT_ID=${PROJECT_ID}
IMAGE_TAG=${IMAGE_TAG:-v1.2.3}

if [ -z "$PROJECT_ID" ]; then
    echo "ERROR: PROJECT_ID environment variable is required."
    exit 1
fi

# Determine the directory where the script is located to find terraform dir
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/../terraform"

echo "Initializing Terraform..."
terraform init -input=false

echo "Fetching current state list to optimize imports..."
# Fetch state list once to avoid multiple remote calls
CURRENT_STATE=$(terraform state list || echo "")

import_resource() {
    local address=$1
    local id=$2
    
    echo "Checking $address..."
    if echo "$CURRENT_STATE" | grep -q "^$address$"; then
        echo "  -> ✓ Already managed by Terraform."
    else
        echo "  -> 📥 Importing $id..."
        terraform import -var-file="tfvars/prod.tfvars" \
            -var="image_tag=${IMAGE_TAG}" \
            -var="firebase_api_key=${FIREBASE_API_KEY}" \
            -var="firebase_auth_domain=${FIREBASE_AUTH_DOMAIN}" \
            -var="firebase_app_id=${FIREBASE_APP_ID}" \
            "$address" "$id" || echo "  -> ⚠️  Could not import $address"
    fi
}

echo "Starting import process for Project: $PROJECT_ID"
echo "--------------------------------------------------"

# Core / Artifact Registry
import_resource "module.infrastructure.google_artifact_registry_repository.action" \
    "projects/${PROJECT_ID}/locations/asia-northeast1/repositories/action"

# Service Accounts
import_resource "module.infrastructure.module.frontend_sa.google_service_account.sa" \
    "projects/${PROJECT_ID}/serviceAccounts/frontend-sa@${PROJECT_ID}.iam.gserviceaccount.com"

import_resource "module.infrastructure.module.act_api_sa.google_service_account.sa" \
    "projects/${PROJECT_ID}/serviceAccounts/act-api-sa@${PROJECT_ID}.iam.gserviceaccount.com"

import_resource "module.infrastructure.module.act_adk_worker_sa.google_service_account.sa" \
    "projects/${PROJECT_ID}/serviceAccounts/act-adk-worker-sa@${PROJECT_ID}.iam.gserviceaccount.com"

import_resource "module.infrastructure.module.pubsub_invoker_sa.google_service_account.sa" \
    "projects/${PROJECT_ID}/serviceAccounts/pubsub-invoker-sa@${PROJECT_ID}.iam.gserviceaccount.com"

import_resource "module.infrastructure.google_service_account.github_deployer" \
    "projects/${PROJECT_ID}/serviceAccounts/github-deployer-sa@${PROJECT_ID}.iam.gserviceaccount.com"

# Cloud Run Services
import_resource "module.infrastructure.module.frontend_service.google_cloud_run_v2_service.service" \
    "projects/${PROJECT_ID}/locations/asia-northeast1/services/frontend"

import_resource "module.infrastructure.module.act_api_service.google_cloud_run_v2_service.service" \
    "projects/${PROJECT_ID}/locations/asia-northeast1/services/act-api"

import_resource "module.infrastructure.module.act_adk_worker_service.google_cloud_run_v2_service.service" \
    "projects/${PROJECT_ID}/locations/asia-northeast1/services/act-adk-worker"

import_resource "module.infrastructure.module.organize_service.google_cloud_run_v2_service.service" \
    "projects/${PROJECT_ID}/locations/asia-northeast1/services/organize"

# Data Stores
import_resource "module.infrastructure.google_redis_instance.main" \
    "projects/${PROJECT_ID}/locations/asia-northeast1/instances/action-redis"

import_resource "module.infrastructure.google_storage_bucket.uploads" \
    "${PROJECT_ID}-uploads"

# Networking
import_resource "module.infrastructure.google_vpc_access_connector.redis_connector" \
    "projects/${PROJECT_ID}/locations/asia-northeast1/connectors/redis-connector"

# Pub/Sub Topics
import_resource "module.infrastructure.google_pubsub_topic.mind_events" \
    "projects/${PROJECT_ID}/topics/mind-events"

import_resource "module.infrastructure.google_pubsub_topic.mind_events_dlq" \
    "projects/${PROJECT_ID}/topics/mind-events-dlq"

# Pub/Sub Subscriptions
SUBS=("sub-a0" "sub-a1" "sub-topic-resolver" "sub-a2" "sub-a3b" "sub-a6" "sub-a3" "sub-a4" "sub-a7" "sub-a5")
for sub in "${SUBS[@]}"; do
    import_resource "module.infrastructure.google_pubsub_subscription.organize_subs[\"$sub\"]" \
        "projects/${PROJECT_ID}/subscriptions/$sub"
done

echo "--------------------------------------------------"
echo "✨ Import process complete. Run 'make terraform-plan' to verify."
