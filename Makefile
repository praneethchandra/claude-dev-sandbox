.PHONY: help build start stop restart enter logs status mode \
        fix-network diagnose proxy-find open export mount \
        metrics metrics-detail metrics-today metrics-all \
        edit-hooks edit-claude skills auth rebuild clean purge check

CONTAINER := claude-dev
COMPOSE   := docker compose
PROJECT   ?=
TO        ?= ~/projects
MODE      ?=

B := \033[1m
G := \033[0;32m
C := \033[0;36m
A := \033[0;33m
D := \033[2m
R := \033[0m

## help: Show all targets
help:
	@echo "" && echo "$(B)Claude Code Dev Sandbox$(R)" && \
	echo "──────────────────────────────────────────────────" && \
	grep -E '^## [a-zA-Z_-]+:' Makefile | sed 's/^## //' | \
	awk -F: '{printf "  $(C)%-22s$(R) %s\n", $$1, $$2}' && echo ""

## build: Build Docker image from scratch
build:
	$(COMPOSE) build --no-cache

## start: Start the sandbox (builds image if needed)
start:
	@[ -f .env ] || (echo "$(A)Run: cp .env.example .env$(R)" && exit 1)
	$(COMPOSE) up -d && echo "$(G)Running$(R)  ->  make enter"

## stop: Stop container (data preserved in volumes)
stop:
	$(COMPOSE) stop

## restart: Stop then start
restart: stop start

## enter: Open interactive shell inside container
enter:
	@docker exec -it $(CONTAINER) zsh 2>/dev/null || \
		(echo "$(A)Not running — run: make start$(R)" && exit 1)

## logs: Tail container output
logs:
	$(COMPOSE) logs -f

## status: Show container status and active mode
status:
	@echo "" && \
	docker ps --filter name=$(CONTAINER) --format "  Status: {{.Status}}" && \
	docker exec $(CONTAINER) switch-mode show 2>/dev/null | sed 's/^/  /' && echo ""

## mode: Set dev mode from host  usage: make mode MODE=full
mode:
	@[ -n "$(MODE)" ] || (echo "Usage: make mode MODE=[minimal|balanced|full|tdd]" && exit 1)
	docker exec $(CONTAINER) switch-mode $(MODE)

# ── Network ───────────────────────────────────────────────────────

## fix-network: Auto-detect and fix network issues (run on Mac, not inside container)
fix-network:
	@bash scripts/fix-network.sh

## diagnose: Run connectivity diagnostics inside container
diagnose:
	@docker exec -it $(CONTAINER) bash /usr/local/claude-scripts/diagnose.sh || \
		(echo "$(A)Not running — make start$(R)" && exit 1)

## proxy-find: Show Mac proxy settings and .env snippet to copy
proxy-find:
	@echo "" && echo "$(B)Mac proxy settings$(R)" && \
	scutil --proxy 2>/dev/null | grep -E "(HTTP|Proxy|Port|Enable)" || echo "  none" && \
	echo "" && echo "$(B)Add to .env if proxy is shown above:$(R)" && \
	PROXY=$$(scutil --proxy 2>/dev/null | \
		awk '/HTTPSProxy\s*:/{s=$$3}/HTTPSPort\s*:/{p=$$3}END{if(s && s!="(null)")print "http://"s":"p}'); \
	[ -n "$$PROXY" ] && \
		echo "  HTTPS_PROXY=$$PROXY" && echo "  HTTP_PROXY=$$PROXY" && \
		echo "  NO_PROXY=localhost,127.0.0.1" || \
		echo "  (no proxy detected — check Docker Desktop proxy settings)" && echo ""

# ── Authentication ────────────────────────────────────────────────

## auth: Sign in via browser (works with corporate Claude subscription)
auth:
	@echo "$(C)Open container shell, then type 'claude' and open the URL shown in your Mac browser.$(R)"
	docker exec -it $(CONTAINER) zsh

## auth-help: Show all authentication options
auth-help:
	@echo "" && echo "$(B)Authentication options$(R)" && echo ""
	@echo "1. $(B)API key$(R)         .env: ANTHROPIC_API_KEY=sk-ant-..."
	@echo "2. $(B)Browser OAuth$(R)   make auth -> type: claude -> open URL in Mac browser"
	@echo "3. $(B)AWS Bedrock$(R)     .env: CLAUDE_CODE_USE_BEDROCK=1 + AWS creds"
	@echo "4. $(B)Vertex AI$(R)       .env: CLAUDE_CODE_USE_VERTEX=1 + GCP project"
	@echo ""
	@echo "$(B)Auth conflict error?$(R)"
	@echo "  Only ONE method should be set at a time."
	@echo "  Check .env — comment out any extras."
	@echo "" && echo "$(B)Network issues?$(R)  make fix-network" && echo ""

# ── IDE integration ───────────────────────────────────────────────

## open: Open VS Code attached to container  usage: make open [PROJECT=name]
open:
	@ID=$$(docker inspect $(CONTAINER) --format='{{.Id}}' 2>/dev/null) && \
	[ -n "$$ID" ] || (echo "$(A)make start first$(R)" && exit 1) && \
	F="/workspace$$([ -n '$(PROJECT)' ] && echo '/$(PROJECT)')" && \
	HEX=$$(printf '%s' "$$ID" | xxd -p | tr -d '\n') && \
	code --folder-uri "vscode-remote://attached-container+$$HEX$$F" 2>/dev/null || \
	echo "$(A)Install VS Code 'Dev Containers' extension$(R)"

# ── Files ─────────────────────────────────────────────────────────

## export: Copy project from container to Mac  usage: make export PROJECT=name [TO=path]
export:
	@[ -n "$(PROJECT)" ] || (echo "Usage: make export PROJECT=<name>" && exit 1)
	@mkdir -p $(TO) && docker cp $(CONTAINER):/workspace/$(PROJECT) $(TO)/
	@echo "$(G)Exported to $(TO)/$(PROJECT)$(R)"

## mount: Set up host folder mount so code is visible on Mac
mount:
	@[ -f docker-compose.override.yml ] || \
		(cp docker-compose.override.yml.example docker-compose.override.yml && \
		 echo "$(G)Created docker-compose.override.yml$(R)")
	$${EDITOR:-nano} docker-compose.override.yml && echo "Run: make restart"

# ── Metrics ───────────────────────────────────────────────────────

## metrics: Token usage dashboard (last 7 days)
metrics:
	@docker exec $(CONTAINER) python3 /usr/local/claude-scripts/metrics.py 2>/dev/null || \
		echo "$(A)make start first$(R)"

## metrics-detail: Per-tool breakdown
metrics-detail:
	@docker exec $(CONTAINER) python3 /usr/local/claude-scripts/metrics.py --detail 2>/dev/null

## metrics-today: Today's usage only
metrics-today:
	@docker exec $(CONTAINER) python3 /usr/local/claude-scripts/metrics.py --today 2>/dev/null

## metrics-all: Full history
metrics-all:
	@docker exec $(CONTAINER) python3 /usr/local/claude-scripts/metrics.py --all 2>/dev/null

# ── Config editing ────────────────────────────────────────────────

## edit-hooks: Edit hooks config (settings.json) inside container
edit-hooks:
	docker exec -it $(CONTAINER) $${EDITOR:-nano} /root/.claude/settings.json

## edit-claude: Edit project CLAUDE.md  usage: make edit-claude PROJECT=name
edit-claude:
	@[ -n "$(PROJECT)" ] || (echo "Usage: make edit-claude PROJECT=<name>" && exit 1)
	docker exec -it $(CONTAINER) $${EDITOR:-nano} /workspace/$(PROJECT)/.claude/CLAUDE.md

## skills: List installed MCP plugins
skills:
	@docker exec $(CONTAINER) claude plugin list 2>/dev/null || \
		echo "make enter -> /plugin to browse and install"

# ── Maintenance ───────────────────────────────────────────────────

## rebuild: Force full image rebuild
rebuild:
	$(COMPOSE) down && $(COMPOSE) build --no-cache --pull && $(COMPOSE) up -d

## clean: Remove container + image (volumes preserved)
clean:
	$(COMPOSE) down --rmi local && echo "$(G)Cleaned (data preserved)$(R)"

## purge: Remove everything including workspace volumes ⚠
purge:
	@read -p "Delete ALL workspace data? Type 'yes': " c && [ "$$c" = "yes" ]
	$(COMPOSE) down -v --rmi local && echo "$(G)Purged$(R)"

## check: Verify prerequisites
check:
	@echo "$(B)Prerequisites$(R)"
	@command -v docker >/dev/null && echo "  $(G)Docker$(R)" || echo "  MISSING: Docker"
	@docker compose version >/dev/null 2>&1 && echo "  $(G)Docker Compose$(R)" || echo "  MISSING"
	@docker info >/dev/null 2>&1 && echo "  $(G)Daemon running$(R)" || \
		echo "  $(A)Open Docker Desktop$(R)"
	@[ -f .env ] && echo "  $(G).env file$(R)" || echo "  $(A)cp .env.example .env$(R)"
	@grep -v "^#" .env 2>/dev/null | \
		grep -qE "ANTHROPIC_API_KEY=sk-|USE_BEDROCK=1|USE_VERTEX=1" && \
		echo "  $(G)Auth configured in .env$(R)" || \
		echo "  $(D)No auth in .env (browser OAuth works — make auth)$(R)"
	@CONFLICTS=$$(grep -v "^#" .env 2>/dev/null | \
		grep -cE "^(ANTHROPIC_API_KEY=sk-|ANTHROPIC_AUTH_TOKEN=.+|CLAUDE_CODE_OAUTH_TOKEN=sk-)" || true); \
		[ "$$CONFLICTS" -gt 1 ] && \
		echo "  $(A)Auth conflict: multiple methods set in .env — comment out all but one$(R)" || true
	@echo "" && echo "  Network: make fix-network  |  Auth: make auth-help"

## pull: Pull latest base image
pull:
	docker pull node:20-bookworm-slim

## push: Build and push to registry  usage: make push REGISTRY=ghcr.io/username
push:
	@[ -n "$(REGISTRY)" ] || (echo "Usage: make push REGISTRY=ghcr.io/username" && exit 1)
	docker build -t $(REGISTRY)/claude-dev-sandbox:latest . && \
	docker push $(REGISTRY)/claude-dev-sandbox:latest
