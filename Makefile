# Cross-platform entry point. Use any of:
#   make build TOOL=coderabbit
#   ./make.sh build coderabbit
#   .\make.ps1 build coderabbit
#
# TOOL     : coderabbit | codex
# WORKSPACE: absolute path to the project you want the CLI to operate on.

TOOL      ?= coderabbit
WORKSPACE ?= $(CURDIR)/sample-workspace

# Convert Windows backslashes to forward slashes for Docker Desktop for Windows.
ifeq ($(OS),Windows_NT)
WORKSPACE := $(subst \,/,$(WORKSPACE))
endif

COMPOSE   := docker compose -f $(TOOL)/docker-compose.yml

.PHONY: help build up down shell rebuild clean ps

help:
	@echo "Usage: make <target> TOOL=<coderabbit|codex> [WORKSPACE=/path/to/project]"
	@echo ""
	@echo "Targets:"
	@echo "  build     Build the Docker image"
	@echo "  up        Start the container (detached, idle)"
	@echo "  down      Stop and remove the container"
	@echo "  shell     Open an interactive bash shell in the container"
	@echo "  rebuild   Rebuild the image (no cache)"
	@echo "  ps        Show container status"
	@echo "  clean     Remove image and auth volume (deletes login)"
	@echo ""
	@echo "Current: TOOL=$(TOOL)  WORKSPACE=$(WORKSPACE)"

build:
	@if [ -z "$$WORKSPACE" ] || [ "$$WORKSPACE" = "$(CURDIR)/sample-workspace" ]; then \
		echo "WARNING: WORKSPACE not set. Using $(WORKSPACE)."; \
		echo "         Set it like:  export WORKSPACE=/path/to/project"; \
	fi
	$(COMPOSE) build

up:
	@if [ -z "$$WORKSPACE" ] || [ "$$WORKSPACE" = "$(CURDIR)/sample-workspace" ]; then \
		echo "ERROR: WORKSPACE not set."; \
		echo "       Set it like:  export WORKSPACE=/path/to/project"; \
		exit 1; \
	fi
	WORKSPACE=$(WORKSPACE) $(COMPOSE) up -d

down:
	$(COMPOSE) down

shell:
	$(COMPOSE) exec $(TOOL) bash

rebuild:
	$(COMPOSE) build --no-cache

ps:
	$(COMPOSE) ps

clean:
	$(COMPOSE) down --rmi local -v
