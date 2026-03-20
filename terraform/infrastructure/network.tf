# ==============================================================================
# Network: VPC Access Connector for Redis
# ==============================================================================

resource "google_vpc_access_connector" "redis_connector" {
  name          = "redis-connector"
  region        = var.region
  ip_cidr_range = "192.168.10.0/28"
  network       = "default"

  min_instances = 2
  max_instances = 3

  depends_on = [module.api_enablement.api_services]
}

