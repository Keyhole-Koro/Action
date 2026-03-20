variable "project_id" { type = string }
variable "region" { type = string }

variable "service_name" {
  type        = string
  description = "Cloud Run service name"
}

variable "image_uri" {
  type        = string
  description = "Container image URI (e.g., region-docker.pkg.dev/project/action/frontend:tag)"
}

variable "service_account_email" {
  type        = string
  description = "Service Account email to run the service"
}

variable "container_port" {
  type        = number
  description = "Container port"
  default     = null
}

variable "container_concurrency" {
  type        = number
  description = "Maximum concurrent requests handled by a single instance"
  default     = null
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment variables for the container"
  default     = {}
}

variable "secret_environment_variables" {
  type = map(object({
    secret  = string
    version = optional(string, "latest")
  }))
  description = "Secret Manager-backed environment variables for the container"
  default     = {}
}

variable "cpu_limit" {
  type        = string
  description = "CPU limit (e.g., '1' or '2')"
  default     = "1"
}

variable "memory_limit" {
  type        = string
  description = "Memory limit (e.g., '512Mi', '1Gi')"
  default     = "512Mi"
}

variable "startup_cpu_boost" {
  type        = bool
  description = "Enable startup CPU boost"
  default     = true
}

variable "vpc_connector_id" {
  type        = string
  description = "VPC Connector ID for private network access"
  default     = ""
}

variable "min_instances" {
  type        = number
  description = "Minimum number of instances"
  default     = 0
}

variable "max_instances" {
  type        = number
  description = "Maximum number of instances"
  default     = 3
}

variable "allow_public" {
  type        = bool
  description = "Allow public access (allUsers invoker)"
  default     = false
}

variable "allowed_invokers" {
  type        = list(string)
  description = "List of service account emails allowed to invoke"
  default     = []
}

variable "ingress" {
  type        = string
  description = "Ingress setting (INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY)"
  default     = "INGRESS_TRAFFIC_ALL"
}
