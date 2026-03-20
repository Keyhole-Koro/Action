# Generic module to deploy a Cloud Run service

resource "google_cloud_run_v2_service" "service" {
  name     = var.service_name
  location = var.region
  ingress  = var.ingress

  deletion_protection = false

  template {
    service_account = var.service_account_email
    max_instance_request_concurrency = var.container_concurrency

    containers {
      image = var.image_uri

      dynamic "ports" {
        for_each = var.container_port != null ? [var.container_port] : []
        content {
          container_port = ports.value
        }
      }

      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secret_environment_variables
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret
              version = env.value.version
            }
          }
        }
      }

      resources {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
        startup_cpu_boost = var.startup_cpu_boost
      }

      # ──────────────────────────────────────────────
      # Startup Probe: 極限までタイムアウトを伸ばす
      # ──────────────────────────────────────────────
      startup_probe {
        initial_delay_seconds = 0
        timeout_seconds       = 240
        period_seconds        = 240
        failure_threshold     = 1
        tcp_socket {
          port = var.container_port
        }
      }
    }

    dynamic "vpc_access" {
      for_each = var.vpc_connector_id != "" ? [var.vpc_connector_id] : []
      content {
        connector = vpc_access.value
        egress    = "PRIVATE_RANGES_ONLY"
      }
    }

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }
  }
}

# IAM binding for public access
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count = var.allow_public ? 1 : 0

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# IAM binding for specific service account
resource "google_cloud_run_v2_service_iam_member" "specific_invoker" {
  for_each = toset(var.allowed_invokers)

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${each.value}"
}
