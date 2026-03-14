.PHONY: generate
generate:
	@echo "Generating protobuf code for all projects..."
	cd contracts && buf generate
	@echo "Done."

.PHONY: lint
lint:
	cd contracts && buf lint

.PHONY: compose-check
compose-check:
	bash ./scripts/compose-check.sh
