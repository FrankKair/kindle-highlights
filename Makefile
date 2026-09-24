build: ## Build the project
	dune build

watch: ## Rebuild on file changes
	dune build --watch

run: ## Run the project
	dune exec kindle_highlights -- "My Clippings.txt"

test: ## Run tests
	dune runtest

test-verbose: ## Run tests (verbose)
	dune runtest --force --verbose

benchmark: ## Benchmark parsing a clippings file
	dune exec bench/parser_bench.exe -- "My Clippings.txt"

fmt: ## Format source code
	dune fmt

clean: ## Remove artefacts
	dune clean

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*##' $(MAKEFILE_LIST) | sort | \
		awk -F ':.*## ' '{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'


.PHONY: build watch run test test-verbose benchmark fmt clean help
.DEFAULT_GOAL := help
