# ==============================================================================
# Messaging: Pub/Sub Topics & Subscriptions
# ==============================================================================

# ──────────────────────────────────────────────
# Pub/Sub Topics
# ──────────────────────────────────────────────

resource "google_pubsub_topic" "mind_events" {
  name = "mind-events"

  depends_on = [module.api_enablement.api_services]
}

resource "google_pubsub_topic" "mind_events_dlq" {
  name = "mind-events-dlq"

  depends_on = [module.api_enablement.api_services]
}

# ──────────────────────────────────────────────
# Push Subscriptions for organize service
# Organized by agent: A0, A1, Topic Resolver, A2, A3B, A6, A3, A4, A7, A5
# ──────────────────────────────────────────────

locals {
  subscriptions = {
    "sub-ingest" = {
      filter = "attributes.type = \"organize.ingest.received\""
    }
    "sub-a0" = {
      filter = "attributes.type = \"media.received\""
    }
    "sub-a1" = {
      filter = "attributes.type = \"input.received\" OR attributes.type = \"atom.reissued\""
    }
    "sub-topic-resolver" = {
      filter = "attributes.type = \"atom.created\""
    }
    "sub-a2" = {
      filter = "attributes.type = \"topic.resolved\""
    }
    "sub-a3b" = {
      filter = "attributes.type = \"draft.updated\" OR attributes.type = \"topic.schema_updated\""
    }
    "sub-a6" = {
      filter = "attributes.type = \"bundle.described\""
    }
    "sub-a3" = {
      filter = "attributes.type = \"bundle.created\""
    }
    "sub-a4" = {
      filter = "attributes.type = \"outline.updated\" OR attributes.type = \"topic.node_changed\""
    }
    "sub-a7" = {
      filter = "attributes.type = \"node.rollup_requested\" OR attributes.type = \"node.rollup.updated\""
    }
    "sub-a5" = {
      filter = "attributes.type = \"topic.metrics.updated\""
    }
  }
}

resource "google_pubsub_subscription" "organize_subs" {
  for_each = local.subscriptions

  name   = each.key
  topic  = google_pubsub_topic.mind_events.name
  filter = each.value.filter

  ack_deadline_seconds = 30

  push_config {
    # サービスURLが確定していない（空）の場合は、一時的にデプロイをスキップさせるか、
    # 有効な形式にする必要があります。ここではURIが取得できるまで apply を待機させる意図で
    # 直接参照を維持しますが、不整合を防ぐため URL 形式をチェックします。
    push_endpoint = module.organize_service.uri != "" ? "${module.organize_service.uri}/events" : "https://temporary-placeholder.run.app/events"

    # OIDC authentication: organize service will verify tokens from pubsub_invoker SA
    oidc_token {
      service_account_email = module.pubsub_invoker_sa.email
      audience              = module.organize_service.uri != "" ? "${module.organize_service.uri}/events" : "https://temporary-placeholder.run.app/events"
    }
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  depends_on = [module.organize_service]
}
