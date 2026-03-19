# Load .env if it exists
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

.PHONY: generate
generate:
	@echo "Generating protobuf code for all projects..."
	cd contracts && buf generate
	@echo "Done."

.PHONY: lint
lint:
	cd contracts && buf lint

.PHONY: build-check
build-check:
	@echo "🔍 Checking frontend (TypeScript)..."
	cd ActionAct/frontend && npm run typecheck
	@echo "🔍 Checking act-api (Go)..."
	cd ActionAct/act-api && go build ./...
	@echo "🔍 Checking act-adk-worker (Python)..."
	cd ActionAct/act-adk-worker && python3 -m compileall app/
	@echo "🔍 Checking organize (TypeScript)..."
	cd ActionOrganize && npm run typecheck
	@echo "✅ All build checks passed!"

.PHONY: compose-check
compose-check:
	bash ./scripts/compose-check.sh

.PHONY: compose-preflight
compose-preflight:
	bash ./scripts/compose-preflight.sh

.PHONY: smoke-test
smoke-test:
	bash ./scripts/smoke-test.sh

.PHONY: frontend-dev
frontend-dev:
	cd ActionAct/frontend && npm run dev

# ──────────────────────────────────┐
#  Production Deployment (Local)    │
# ──────────────────────────────────┘

.PHONY: docker-build
docker-build:
	@echo "Building Docker images (IMAGE_TAG=$(IMAGE_TAG))..."
	@if [ -z "$(IMAGE_TAG)" ]; then echo "ERROR: IMAGE_TAG is required. Usage: make docker-build IMAGE_TAG=v1.0.0"; exit 1; fi
	@if [ -z "$${PROJECT_ID}" ]; then echo "ERROR: PROJECT_ID is required."; exit 1; fi
	@if [ -z "$${FIREBASE_API_KEY}" ] || [ "$${FIREBASE_API_KEY}" = "replace-me" ]; then echo "ERROR: FIREBASE_API_KEY is required and must not be replace-me."; exit 1; fi
	@if [ -z "$${FIREBASE_AUTH_DOMAIN}" ] || [ "$${FIREBASE_AUTH_DOMAIN}" = "replace-me.firebaseapp.com" ]; then echo "ERROR: FIREBASE_AUTH_DOMAIN is required and must not be replace-me.firebaseapp.com."; exit 1; fi
	@if [ -z "$${FIREBASE_APP_ID}" ] || [ "$${FIREBASE_APP_ID}" = "replace-me" ]; then echo "ERROR: FIREBASE_APP_ID is required and must not be replace-me."; exit 1; fi
	docker build \
		--load \
		--build-arg NEXT_PUBLIC_USE_MOCKS=false \
		--build-arg NEXT_PUBLIC_FIREBASE_API_KEY="$${FIREBASE_API_KEY}" \
		--build-arg NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN="$${FIREBASE_AUTH_DOMAIN}" \
		--build-arg NEXT_PUBLIC_FIREBASE_APP_ID="$${FIREBASE_APP_ID}" \
		--build-arg NEXT_PUBLIC_GCLOUD_PROJECT="$${PROJECT_ID}" \
		-t asia-northeast1-docker.pkg.dev/$${PROJECT_ID}/action/frontend:$(IMAGE_TAG) \
		ActionAct/frontend
	docker build \
		--load \
		-t asia-northeast1-docker.pkg.dev/$${PROJECT_ID}/action/act-api:$(IMAGE_TAG) \
		ActionAct/act-api
	docker build \
		--load \
		-t asia-northeast1-docker.pkg.dev/$${PROJECT_ID}/action/act-adk-worker:$(IMAGE_TAG) \
		ActionAct/act-adk-worker
	docker build \
		--load \
		-t asia-northeast1-docker.pkg.dev/$${PROJECT_ID}/action/organize:$(IMAGE_TAG) \
		ActionOrganize
	@echo "Build complete."

.PHONY: docker-push
docker-push:
	@echo "Pushing Docker images (IMAGE_TAG=$(IMAGE_TAG))..."
	@if [ -z "$(IMAGE_TAG)" ]; then echo "ERROR: IMAGE_TAG is required. Usage: make docker-push IMAGE_TAG=v1.0.0"; exit 1; fi
	docker push asia-northeast1-docker.pkg.dev/$${PROJECT_ID}/action/frontend:$(IMAGE_TAG)
	docker push asia-northeast1-docker.pkg.dev/$${PROJECT_ID}/action/act-api:$(IMAGE_TAG)
	docker push asia-northeast1-docker.pkg.dev/$${PROJECT_ID}/action/act-adk-worker:$(IMAGE_TAG)
	docker push asia-northeast1-docker.pkg.dev/$${PROJECT_ID}/action/organize:$(IMAGE_TAG)
	@echo "Push complete."

.PHONY: terraform-plan
terraform-plan:
	@echo "Running terraform plan..."
	@if [ -z "$(IMAGE_TAG)" ]; then echo "ERROR: IMAGE_TAG is required."; exit 1; fi
	cd terraform && \
		terraform init && \
		terraform plan \
			-var-file="tfvars/prod.tfvars" \
			-var="image_tag=$(IMAGE_TAG)" \
			-var="firebase_api_key=$${FIREBASE_API_KEY}" \
			-var="firebase_auth_domain=$${FIREBASE_AUTH_DOMAIN}" \
			-var="firebase_app_id=$${FIREBASE_APP_ID}"

.PHONY: terraform-apply
terraform-apply:
	@echo "Running terraform apply..."
	@if [ -z "$(IMAGE_TAG)" ]; then echo "ERROR: IMAGE_TAG is required."; exit 1; fi
	cd terraform && \
		terraform init && \
		terraform apply -auto-approve \
			-var-file="tfvars/prod.tfvars" \
			-var="image_tag=$(IMAGE_TAG)" \
			-var="firebase_api_key=$${FIREBASE_API_KEY}" \
			-var="firebase_auth_domain=$${FIREBASE_AUTH_DOMAIN}" \
			-var="firebase_app_id=$${FIREBASE_APP_ID}"

.PHONY: terraform-import-all
terraform-import-all:
	@echo "Importing existing GCP resources into Terraform state..."
	@bash ./scripts/terraform-import.sh

.PHONY: deploy-local
deploy-local: docker-build docker-push terraform-apply
	@echo "=== Local deployment complete ==="
	@echo "Deployed services:"
	gcloud run services list --region asia-northeast1 --format="table(name,status.url)"

.PHONY: deploy-manually
deploy-manually:
	@echo "Running full manual deploy pipeline..."
	@if [ -z "$${PROJECT_ID}" ]; then echo "ERROR: PROJECT_ID is required. Example: export PROJECT_ID=action-490203"; exit 1; fi
	@TAG="$(IMAGE_TAG)"; \
	if [ -z "$$TAG" ]; then TAG="$$(git rev-parse --short HEAD)"; fi; \
	echo "Using IMAGE_TAG=$$TAG"; \
	$(MAKE) docker-build IMAGE_TAG=$$TAG PROJECT_ID=$${PROJECT_ID} && \
	$(MAKE) docker-push IMAGE_TAG=$$TAG PROJECT_ID=$${PROJECT_ID} && \
	$(MAKE) terraform-apply IMAGE_TAG=$$TAG && \
	echo "=== Manual deploy complete ===" && \
	gcloud run services list --region asia-northeast1 --format="table(name,status.url)"
