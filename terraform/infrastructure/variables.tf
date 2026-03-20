variable "project_id" {
  type        = string
  description = "Google Cloud Project ID"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid GCP project ID."
  }
}

variable "region" {
  type        = string
  default     = "asia-northeast1"
  description = "GCP Deploy Region"
}

variable "image_tag" {
  type        = string
  description = "Container image tag (git SHA or semantic version)"
  validation {
    condition     = length(var.image_tag) > 0
    error_message = "image_tag must not be empty."
  }
}

variable "github_repo" {
  type        = string
  description = "GitHub repository in owner/repo format (e.g., your-org/Action)"
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$", var.github_repo))
    error_message = "github_repo must be in owner/repo format."
  }
}

variable "redis_memory_size_gb" {
  type        = number
  default     = 1
  description = "Memorystore Redis memory size (GB)"
  validation {
    condition     = var.redis_memory_size_gb >= 1 && var.redis_memory_size_gb <= 300
    error_message = "redis_memory_size_gb must be between 1 and 300 GB."
  }
}

variable "gemini_model_fast" {
  type        = string
  default     = "gemini-1.5-flash"
  description = "Fast-tier Gemini model (e.g., gemini-1.5-flash)"
}

variable "gemini_model_quality" {
  type        = string
  default     = "gemini-1.5-pro"
  description = "Quality-tier Gemini model (e.g., gemini-1.5-pro)"
}

variable "organize_gcs_bucket" {
  type        = string
  default     = "action-uploads"
  description = "GCS bucket name for uploads (project_id suffix is appended)"
}

variable "act_api_cors_allowed_origins" {
  type        = list(string)
  description = "Allowed CORS origins for act-api"
  validation {
    condition     = length(var.act_api_cors_allowed_origins) > 0
    error_message = "act_api_cors_allowed_origins must contain at least one origin."
  }
}

variable "firebase_api_key" {
  type        = string
  description = "Firebase API Key"
}

variable "google_api_key" {
  type        = string
  description = "Google AI Studio API Key"
  sensitive   = true
}

variable "firebase_auth_domain" {
  type        = string
  description = "Firebase Auth Domain"
}

variable "firebase_app_id" {
  type        = string
  description = "Firebase App ID"
}

variable "action_ingest_workspace_id" {
  type        = string
  default     = "default"
  description = "Workspace ID used by ActionIngest when publishing organize.ingest.received jobs"
}
