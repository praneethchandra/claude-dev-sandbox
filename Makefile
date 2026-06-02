.PHONY: help build start stop restart enter logs status mode \
        open export mount metrics metrics-detail metrics-today metrics-all \
        edit-hooks edit-claude skills rebuild clean purge check auth auth-help token

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
	@echo "──────────────────────────────────────────────────────────────"
	@grep -E '^## [a-zA-Z_-]+:' Makefile | sed 's/^## //' | \
		awk -F: '{printf "  $(CYAN)%-24s$(RESET) %s\n", $$1, $$2}'
	@echo ""

# ── Container lifecycle ───────────────────────────────────────────

## build: Build the Docker image from scratch
build:
	$(COMPOSE) build --no-cache && echo "$(GREEN)Done$(RESET)"

## start: Start the sandbox (builds if needed)
start:
	@[ -f .env ] || (echo "$(AMBER)Copy .env.example to .env first$(RESET)" && exit 1)
	$(COMPOSE) up -d && echo "$(GREEN)Running$(RESET)  ->  make enter"

## stop: Stop the container (data preserved)
stop:
	$(COMPOSE) stop && echo "$(GREEN)Stopped$(RESET)"

## restart: Stop then start
restart: stop start

## enter: Open an interactive shell inside the container
enter:
	@docker exec -it $(CONTAINER) zsh 2>/dev/null || \
		(echo "$(AMBER)Not running - run: make start$(RESET)" && exit 1)

## logs: Tail container output
logs:
	$(COMPOSE) logs -f

## status: Show container status, auth method, and active mode
status:
	@echo ""
	@echo "$(BOLD)Container:$(RESET)  $$(docker ps --filter name=$(CONTAINER) --format '{{.Status}}' 2>/dev/null || echo 'not running')"
	@echo "$(BOLD)Mode:$(RESET)       $$(docker exec $(CONTAINER) switch-mode show 2>/dev/null || echo 'container not running')"
	@echo "$(BOLD)Claude:$(RESET)     $$(docker exec $(CONTAINER) claude --version 2>/dev/null | head -1 || echo 'n/a')"
	@echo ""

## mode: Set dev mode from host  usage: make mode MODE=full
mode:
	@[ -n "$(MODE)" ] || (echo "Usage: make mode MODE=[minimal|balanced|full|tdd]" && exit 1)
	docker exec $(CONTAINER) switch-mode $(MODE)

# ── Authentication ────────────────────────────────────────────────

## auth: Authenticate via browser (for corporate/subscription users)
auth:
	@echo ""
	@echo "$(BOLD)Browser OAuth authentication$(RESET)"
	@echo "─────────────────────────────────────────"
	@echo "Opening a shell in the container..."
	@echo "Type $(BOLD)claude$(RESET) when the prompt appears."
	@echo "Claude will show a URL - open it in your Mac browser."
	@echo "Sign in with your corporate Claude account."
	@echo "The token is saved in the Docker volume automatically."
	@echo ""
	docker exec -it $(CONTAINER) zsh

## token: Generate a long-lived OAuth token (run on Mac, not in Docker)
token:
	@echo ""
	@echo "$(BOLD)Generating a long-lived OAuth token$(RESET)"
	@echo "─────────────────────────────────────────"
	@echo "This runs on your Mac (not in Docker)."
	@echo "You need Claude Code installed locally: npm i -g @anthropic-ai/claude-code"
	@echo ""
	@command -v claude >/dev/null 2>&1 || \
		(echo "$(AMBER)Claude Code not on Mac. Run: npm i -g @anthropic-ai/claude-code$(RESET)" && exit 1)
	@claude auth token
	@echo ""
	@echo "$(GREEN)Copy the token above into .env as:$(RESET)"
	@echo "  CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-..."
	@echo "Then: make restart"
	@echo ""

## auth-help: Show all authentication options with instructions
auth-help:
	@echo ""
	@echo "$(BOLD)Claude Code Authentication Options$(RESET)"
	@echo "══════════════════════════════════════════════════════════════"
	@echo ""
	@echo "$(BOLD)Option 1 - Browser OAuth (easiest, no key needed)$(RESET)"
	@echo "  Works with Pro, Max, Team, or Enterprise Claude subscription."
	@echo "  make auth    <- opens container shell"
	@echo "  Then type: claude"
	@echo "  Open the URL shown in your Mac browser and sign in."
	@echo "  Token saved in Docker volume - persists forever."
	@echo ""
	@echo "$(BOLD)Option 2 - Long-lived OAuth token (for CI/headless)$(RESET)"
	@echo "  Generate once on your Mac: make token"
	@echo "  Add to .env: CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-..."
	@echo "  make restart"
	@echo ""
	@echo "$(BOLD)Option 3 - AWS Bedrock$(RESET)"
	@echo "  If your company uses Claude through AWS."
	@echo "  Add to .env:"
	@echo "    CLAUDE_CODE_USE_BEDROCK=1"
	@echo "    AWS_ACCESS_KEY_ID=..."
	@echo "    AWS_SECRET_ACCESS_KEY=..."
	@echo "    AWS_REGION=us-east-1"
	@echo "  Or mount ~/.aws via docker-compose.override.yml"
	@echo ""
	@echo "$(BOLD)Option 4 - Google Vertex AI$(RESET)"
	@echo "  If your company uses Claude through GCP."
	@echo "  Add to .env:"
	@echo "    CLAUDE_CODE_USE_VERTEX=1"
	@echo "    CLOUD_ML_REGION=us-east5"
	@echo "    ANTHROPIC_VERTEX_PROJECT_ID=your-project"
	@echo ""
	@echo "$(BOLD)Option 5 - Internal LLM gateway / proxy$(RESET)"
	@echo "  If your company has an internal AI gateway."
	@echo "  Ask IT for the gateway URL and bearer token. Add to .env:"
	@echo "    ANTHROPIC_BASE_URL=https://ai-gateway.yourcompany.com"
	@echo "    ANTHROPIC_AUTH_TOKEN=your-bearer-token"
	@echo ""
	@echo "$(BOLD)Option 6 - Anthropic API key$(RESET)"
	@echo "  Ask IT admin for a key from console.anthropic.com."
	@echo "  Add to .env: ANTHROPIC_API_KEY=sk-ant-api03-..."
	@echo ""

# ── IDE integration ───────────────────────────────────────────────

## open: Open VS Code attached to the running container
##       usage: make open  OR  make open PROJECT=my-app
open:
	@CONTAINER_ID=$$(docker inspect $(CONTAINER) --format='{{.Id}}' 2>/dev/null) && \
	[ -n "$$CONTAINER_ID" ] || (echo "$(AMBER)Not running - make start$(RESET)" && exit 1) && \
	FOLDER="/workspace$$([ -n '$(PROJECT)' ] && echo '/$(PROJECT)' || echo '')" && \
	HEX=$$(printf '%s' "$$CONTAINER_ID" | xxd -p | tr -d '\n') && \
	code --folder-uri "vscode-remote://attached-container+$$HEX$$FOLDER" 2>/dev/null || \
	echo "$(AMBER)Install VS Code 'Dev Containers' extension and add 'code' to PATH$(RESET)"

# ── Files ─────────────────────────────────────────────────────────

## export: Copy a project from container to Mac
##         usage: make export PROJECT=my-app  [TO=~/Desktop]
export:
	@[ -n "$(PROJECT)" ] || (echo "Usage: make export PROJECT=<name> [TO=~/projects]" && exit 1)
	@mkdir -p $(TO)
	docker cp $(CONTAINER):/workspace/$(PROJECT) $(TO)/
	@echo "$(GREEN)Exported to $(TO)/$(PROJECT)$(RESET)"

## mount: Set up host folder mount so code is visible on Mac
mount:
	@[ -f docker-compose.override.yml ] || \
		(cp docker-compose.override.yml.example docker-compose.override.yml && \
		 echo "$(GREEN)Created docker-compose.override.yml$(RESET)")
	@echo "$(CYAN)Edit the file, then: make restart$(RESET)"
	@$${EDITOR:-nano} docker-compose.override.yml

# ── Metrics ───────────────────────────────────────────────────────

## metrics: Token usage dashboard (last 7 days)
metrics:
	@docker exec $(CONTAINER) python3 /usr/local/claude-scripts/metrics.py 2>/dev/null || \
		echo "$(AMBER)Not running - make start$(RESET)"

## metrics-detail: Per-tool breakdown with timestamps
metrics-detail:
	@docker exec $(CONTAINER) python3 /usr/local/claude-scripts/metrics.py --detail 2>/dev/null || true

## metrics-today: Today's usage only
metrics-today:
	@docker exec $(CONTAINER) python3 /usr/local/claude-scripts/metrics.py --today 2>/dev/null || true

## metrics-all: Full history
metrics-all:
	@docker exec $(CONTAINER) python3 /usr/local/claude-scripts/metrics.py --all 2>/dev/null || true

# ── Config editing ────────────────────────────────────────────────

## edit-hooks: Edit the hooks config (settings.json)
edit-hooks:
	docker exec -it $(CONTAINER) $${EDITOR:-nano} /root/.claude/settings.json

## edit-claude: Edit CLAUDE.md for a project
##              usage: make edit-claude PROJECT=my-app
edit-claude:
	@[ -n "$(PROJECT)" ] || (echo "Usage: make edit-claude PROJECT=<name>" && exit 1)
	docker exec -it $(CONTAINER) $${EDITOR:-nano} /workspace/$(PROJECT)/.claude/CLAUDE.md

## skills: List installed MCP plugins
skills:
	@docker exec $(CONTAINER) claude plugin list 2>/dev/null || \
		echo "Run 'make enter' then '/plugin' to install plugins"

# ── Maintenance ───────────────────────────────────────────────────

## rebuild: Force full image rebuild
rebuild:
	$(COMPOSE) down && $(COMPOSE) build --no-cache --pull && $(COMPOSE) up -d

## clean: Remove container + image (volumes preserved)
clean:
	$(COMPOSE) down --rmi local && echo "$(GREEN)Cleaned (data preserved)$(RESET)"

## purge: Remove everything including volumes
purge:
	@echo "$(AMBER)This will delete all workspace data$(RESET)"
	@read -p "Type 'yes' to confirm: " c && [ "$$c" = "yes" ]
	$(COMPOSE) down -v --rmi local && echo "$(GREEN)Purged$(RESET)"

## check: Verify prerequisites
check:
	@echo "$(BOLD)Checking prerequisites...$(RESET)"
	@command -v docker >/dev/null && echo "  $(GREEN)Docker$(RESET)" || echo "  MISSING: Docker"
	@docker compose version >/dev/null 2>&1 && echo "  $(GREEN)Docker Compose$(RESET)" || echo "  MISSING: Compose"
	@docker info >/dev/null 2>&1 && echo "  $(GREEN)Docker daemon running$(RESET)" || \
		echo "  $(AMBER)Docker daemon not running - open Docker Desktop$(RESET)"
	@[ -f .env ] && echo "  $(GREEN).env file$(RESET)" || echo "  $(AMBER).env missing - cp .env.example .env$(RESET)"
	@[ -f docker-compose.override.yml ] && \
		echo "  $(GREEN)Host mount configured$(RESET)" || \
		echo "  $(DIM)No host mount (run 'make mount' to expose files on Mac)$(RESET)"
	@echo ""
	@echo "  Auth check:"
	@grep -v "^#" .env 2>/dev/null | grep -qE "ANTHROPIC_API_KEY=sk-|CLAUDE_CODE_OAUTH_TOKEN=sk-|CLAUDE_CODE_USE_BEDROCK=1|CLAUDE_CODE_USE_VERTEX=1|ANTHROPIC_AUTH_TOKEN=." && \
		echo "  $(GREEN)Auth configured in .env$(RESET)" || \
		echo "  $(DIM)No auth in .env (browser OAuth also works - see: make auth-help)$(RESET)"
	@echo ""

## pull: Pull latest base image
pull:
	docker pull node:20-bookworm-slim

## push: Build and push to registry
##       usage: make push REGISTRY=ghcr.io/username
push:
	@[ -n "$(REGISTRY)" ] || (echo "Usage: make push REGISTRY=ghcr.io/username" && exit 1)
	docker build -t $(REGISTRY)/claude-dev-sandbox:latest . && \
	docker push $(REGISTRY)/claude-dev-sandbox:latest
