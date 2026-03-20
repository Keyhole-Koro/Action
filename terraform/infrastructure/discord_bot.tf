# ==============================================================================
# Discord Bot VM
# ==============================================================================

resource "google_compute_instance" "discord_bot" {
  name         = "discord-bot"
  project      = var.project_id
  zone         = var.discord_bot_zone
  machine_type = var.discord_bot_machine_type

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  service_account {
    email  = module.discord_bot_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["discord-bot"]

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    export DEBIAN_FRONTEND=noninteractive

    apt-get update
    apt-get install -y ca-certificates curl gnupg docker.io apt-transport-https
    systemctl enable docker
    systemctl start docker

    install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/google-cloud.gpg
    echo "deb [signed-by=/etc/apt/keyrings/google-cloud.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list
    apt-get update
    apt-get install -y google-cloud-cli

    gcloud auth configure-docker ${var.region}-docker.pkg.dev --quiet

    DISCORD_BOT_TOKEN="$(gcloud secrets versions access latest --secret=${google_secret_manager_secret.discord_bot_token.secret_id} --project=${var.project_id} | tr -d '\n')"

    cat > /etc/action-discord-bot.env <<EOF
DISCORD_BOT_TOKEN=$${DISCORD_BOT_TOKEN}
GOOGLE_CLOUD_PROJECT=${var.project_id}
GCS_BUCKET=${google_storage_bucket.uploads.name}
PUBSUB_TOPIC_NAME=${google_pubsub_topic.mind_events.name}
EOF

    docker rm -f action-discord-bot || true
    docker pull ${local.image_base}/discord-bot:${var.image_tag}
    docker run -d \
      --name action-discord-bot \
      --restart always \
      --env-file /etc/action-discord-bot.env \
      ${local.image_base}/discord-bot:${var.image_tag}
  EOT

  labels = {
    service = "discord-bot"
  }

  depends_on = [
    module.api_enablement.api_services,
    google_secret_manager_secret_version.discord_bot_token,
    google_storage_bucket.uploads,
    google_pubsub_topic.mind_events,
  ]
}
