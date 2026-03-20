project_id                = "action-490203"
region                    = "asia-northeast1"
github_repo               = "Keyhole-Koro/Action"
redis_memory_size_gb      = 1
gemini_model_fast         = "gemini-3-flash-preview"
gemini_model_quality      = "gemini-3-pro-preview"
organize_gcs_bucket       = "action-uploads"
act_api_cors_allowed_origins = [
	"https://action-490203.web.app",
	"https://action-490203.firebaseapp.com",
	"https://frontend-wmd222x7za-an.a.run.app"
]

# Note: image_tag, firebase_* are provided via -var flags from CI/CD or Makefile
