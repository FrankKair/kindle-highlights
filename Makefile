DUNE ?= opam exec -- dune

build: ## Build the project
	$(DUNE) build

install: ## Build and install into the selected opam switch
	opam install .

watch: ## Rebuild on file changes
	$(DUNE) build --watch

run: ## Browse saved highlights
	$(DUNE) exec kindle_highlights

load: ## Replace saved highlights from FILE and browse
	@test -n "$(FILE)" || { echo "Usage: make load FILE=/path/to/clippings.txt" >&2; exit 2; }
	$(DUNE) exec kindle_highlights -- load "$(FILE)"

test: ## Run tests
	$(DUNE) runtest

test-verbose: ## Run tests (verbose)
	$(DUNE) runtest --force --verbose

benchmark: ## Benchmark parsing a clippings file
	@test -n "$(FILE)" || { echo "Usage: make benchmark FILE=/path/to/clippings.txt" >&2; exit 2; }
	$(DUNE) exec bench/parser_bench.exe -- "$(FILE)"

fmt: ## Format source code
	$(DUNE) fmt

clean: ## Remove artefacts
	$(DUNE) clean

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*##' $(MAKEFILE_LIST) | sort | \
		awk -F ':.*## ' '{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'


.PHONY: build install watch run load test test-verbose benchmark fmt clean help
.DEFAULT_GOAL := help
