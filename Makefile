.PHONY: help build start stop restart enter logs status mode \
        open export mount metrics metrics-detail metrics-today metrics-all \
        edit-hooks edit-claude skills rebuild clean purge check pull push

CONTAINER := claude-dev
IMAGE     := claude-dev-sandbox:latest
COMPOSE   := docker compose
PROJECT   ?=
TO        ?= ~/projects
MODE      ?=

BOLD  := \033[1m
GREEN := \033[0;32m
CYAN  := \033[0;36m
AMBER := \033[0;33m
DIM   := \033[2m
RESET := \033[0m

## help: Show all available targets
help:
	@echo ""
	@echo "$(BOLD)Claude Code Dev Sandbox$(RESET)"
	@echo "───────────────────────────────────────────────────────────"
	@grep -E '^## [a-zA-Z_-]+:' Makefile | sed 's/^## //' | \
		awk -F: '{printf "  $(CYAN)%-24s$(RESET) %s\n", $$1, $$2}'
	@echo ""

# ── Container lifecycle ───────────────────────────────────────────

## build: Build the Docker image from scratch
build:
	@echo "$(CYAN)Building image…$(RESET)"
	$(COMPOSE) build --no-cache
	@echo "$(GREEN)✓ Build complete$(RESET)"

## start: Start the sandbox (builds image if needed)
start:
	@[ -f .env ] || (echo "$(AMBER)⚠  .env not found — run: cp .env.example .env$(RESET)" && exit 1)
	@grep -q "YOUR_KEY_HERE" .env 2>/dev/null && \
		echo "$(AMBER)⚠  Replace placeholder key in .env first$(RESET)" && exit 1 || true
	@echo "$(CYAN)Starting Claude Code Dev Sandbox…$(RESET)"
	$(COMPOSE) up -d
	@echo "$(GREEN)✓ Running$(RESET)  →  make enter"

## stop: Stop the container (data preserved in volumes)
stop:
	$(COMPOSE) stop && echo "$(GREEN)✓ Stopped$(RESET)"

## restart: Stop then start
restart: stop start

## enter: Open an interactive shell inside the container
enter:
	@docker exec -it $(CONTAINER) zsh 2>/dev/null || \
		(echo "$(AMBER)Container not running — run: make start$(RESET)" && exit 1)

## logs: Tail container output
logs:
	$(COMPOSE) logs -f

## status: Show container status, active mode, and Claude version
status:
	@echo ""
	@echo "$(BOLD)Container:$(RESET)  $$(docker ps --filter name=$(CONTAINER) \
		--format '{{.Status}}' 2>/dev/null || echo 'not running')"
	@echo "$(BOLD)Mode:$(RESET)       $$(docker exec $(CONTAINER) switch-mode show \
		2>/dev/null || echo 'container not running')"
	@echo "$(BOLD)Claude:$(RESET)     $$(docker exec $(CONTAINER) claude --version \
		2>/dev/null | head -1 || echo 'n/a')"
	@echo ""

## mode: Set dev mode from host — usage: make mode MODE=full
mode:
	@[ -n "$(MODE)" ] || (echo "Usage: make mode MODE=[minimal|balanced|full|tdd]" && exit 1)
	@docker exec $(CONTAINER) switch-mode $(MODE)

# ── IDE integration ───────────────────────────────────────────────

## open: Open VS Code attached to the running container
##       Usage:  make open  OR  make open PROJECT=my-app
open:
	@CONTAINER_ID=$$(docker inspect $(CONTAINER) --format='{{.Id}}' 2>/dev/null) && \
	[ -n "$$CONTAINER_ID" ] || (echo "$(AMBER)Container not running — make start$(RESET)" && exit 1) && \
	FOLDER="/workspace$$([ -n '$(PROJECT)' ] && echo '/$(PROJECT)' || echo '')" && \
	HEX=$$(printf '%s' "$$CONTAINER_ID" | xxd -p | tr -d '\n') && \
	code --folder-uri "vscode-remote://attached-container+$$HEX$$FOLDER" 2>/dev/null || \
	echo "$(AMBER)Tip: install the VS Code 'Dev Containers' extension and add 'code' to PATH$(RESET)"

# ── Files: export & mount ─────────────────────────────────────────

## export: Copy a project from container → Mac
##         Usage: make export PROJECT=my-app  [TO=~/Desktop]
export:
	@[ -n "$(PROJECT)" ] || (echo "Usage: make export PROJECT=<name> [TO=~/projects]" && exit 1)
	@echo "$(CYAN)Exporting /workspace/$(PROJECT) → $(TO)/$(PROJECT)…$(RESET)"
	@mkdir -p $(TO)
	@docker cp $(CONTAINER):/workspace/$(PROJECT) $(TO)/
	@echo "$(GREEN)✓ Exported to $(TO)/$(PROJECT)$(RESET)"

## mount: Set up host folder mount so code is visible on Mac
mount:
	@if [ -f docker-compose.override.yml ]; then \
		echo "$(AMBER)docker-compose.override.yml already exists$(RESET)"; \
	else \
		cp docker-compose.override.yml.example docker-compose.override.yml; \
		echo "$(GREEN)✓ Created docker-compose.override.yml$(RESET)"; \
	fi
	@echo "$(CYAN)Edit the file, then run: make restart$(RESET)"
	@$${EDITOR:-nano} docker-compose.override.yml

# ── Metrics & token usage ─────────────────────────────────────────

## metrics: Show token usage dashboard (last 7 days)
metrics:
	@docker exec $(CONTAINER) python3 /usr/local/claude-scripts/metrics.py 2>/dev/null || \
		echo "$(AMBER)Container not running — make start$(RESET)"

## metrics-detail: Per-tool breakdown with timestamps
metrics-detail:
	@docker exec $(CONTAINER) python3 /usr/local/claude-scripts/metrics.py --detail 2>/dev/null || \
		echo "$(AMBER)Container not running — make start$(RESET)"

## metrics-today: Today's usage only
metrics-today:
	@docker exec $(CONTAINER) python3 /usr/local/claude-scripts/metrics.py --today 2>/dev/null || true

## metrics-all: Full history
metrics-all:
	@docker exec $(CONTAINER) python3 /usr/local/claude-scripts/metrics.py --all 2>/dev/null || true

# ── Config editing ────────────────────────────────────────────────

## edit-hooks: Edit the hooks config (settings.json) inside container
edit-hooks:
	@docker exec -it $(CONTAINER) $${EDITOR:-nano} /root/.claude/settings.json

## edit-claude: Edit CLAUDE.md for a project
##              Usage: make edit-claude PROJECT=my-app
edit-claude:
	@[ -n "$(PROJECT)" ] || (echo "Usage: make edit-claude PROJECT=<name>" && exit 1)
	@docker exec -it $(CONTAINER) $${EDITOR:-nano} /workspace/$(PROJECT)/.claude/CLAUDE.md

## skills: List installed MCP plugins
skills:
	@echo "$(CYAN)Installed MCP plugins:$(RESET)"
	@docker exec $(CONTAINER) claude plugin list 2>/dev/null || \
		echo "  Run 'make enter' then '/plugin' to install plugins"

# ── Maintenance ───────────────────────────────────────────────────

## rebuild: Force full image rebuild and restart
rebuild:
	@echo "$(CYAN)Rebuilding from scratch…$(RESET)"
	$(COMPOSE) down
	$(COMPOSE) build --no-cache --pull
	$(COMPOSE) up -d
	@echo "$(GREEN)✓ Rebuild complete$(RESET)"

## clean: Remove container + image (volumes preserved)
clean:
	$(COMPOSE) down --rmi local
	@echo "$(GREEN)✓ Cleaned (workspace data preserved)$(RESET)"

## purge: Remove everything including workspace data ⚠️
purge:
	@echo "$(AMBER)This will delete all workspace data in Docker volumes.$(RESET)"
	@read -p "Type 'yes' to confirm: " c && [ "$$c" = "yes" ]
	$(COMPOSE) down -v --rmi local
	@echo "$(GREEN)✓ Purged$(RESET)"

## check: Verify prerequisites before first run
check:
	@echo "$(BOLD)Checking prerequisites…$(RESET)"
	@command -v docker    >/dev/null && echo "  $(GREEN)✓ Docker$(RESET)" \
		|| echo "  ✗ Docker not found — install Docker Desktop"
	@docker compose version >/dev/null 2>&1 && echo "  $(GREEN)✓ Docker Compose$(RESET)" \
		|| echo "  ✗ Docker Compose not found"
	@docker info >/dev/null 2>&1 && echo "  $(GREEN)✓ Docker daemon running$(RESET)" \
		|| echo "  $(AMBER)⚠  Docker daemon not running — open Docker Desktop$(RESET)"
	@[ -f .env ] && echo "  $(GREEN)✓ .env file$(RESET)" \
		|| echo "  $(AMBER)⚠  .env missing — run: cp .env.example .env$(RESET)"
	@grep -q "sk-" .env 2>/dev/null && echo "  $(GREEN)✓ API key set$(RESET)" \
		|| echo "  $(AMBER)⚠  ANTHROPIC_API_KEY not set in .env$(RESET)"
	@[ -f docker-compose.override.yml ] && echo "  $(GREEN)✓ Host mount configured$(RESET)" \
		|| echo "  $(DIM)  (no override — run 'make mount' to expose files on Mac)$(RESET)"
	@echo ""

## pull: Pull latest base image
pull:
	docker pull node:20-bookworm-slim

## push: Build and push image to a registry
##       Usage: make push REGISTRY=ghcr.io/username
push:
	@[ -n "$(REGISTRY)" ] || (echo "Usage: make push REGISTRY=ghcr.io/username" && exit 1)
	docker build -t $(REGISTRY)/claude-dev-sandbox:latest .
	docker push $(REGISTRY)/claude-dev-sandbox:latest
