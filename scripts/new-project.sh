#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# new-project.sh — bootstrap a project with full Claude Code setup
# Usage: new-project <name> [stack]
# Stack options: typescript | python | fullstack | generic
# ─────────────────────────────────────────────────────────────────

PROJECT="$1"
STACK="${2:-typescript}"
WORKSPACE="/workspace"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
AMBER='\033[0;33m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

if [ -z "$PROJECT" ]; then
    echo "Usage: new-project <name> [typescript|python|fullstack|generic]"
    exit 1
fi

PROJECT_DIR="$WORKSPACE/$PROJECT"

if [ -d "$PROJECT_DIR" ]; then
    echo -e "${AMBER}⚠  $PROJECT_DIR already exists${RESET}"
    read -p "Continue and overwrite .claude/ folder? [y/N] " confirm
    [ "$confirm" = "y" ] || exit 0
fi

echo -e "${CYAN}Creating project: ${BOLD}$PROJECT${RESET}${CYAN} (stack: $STACK)${RESET}"

# ── Create directory structure ───────────────────────────────────
mkdir -p "$PROJECT_DIR/.claude"
cd "$PROJECT_DIR"

# ── Git init ─────────────────────────────────────────────────────
if [ ! -d ".git" ]; then
    git init
    git commit --allow-empty -m "chore: initial commit"
fi

# ── Copy mode configs ─────────────────────────────────────────────
cp ~/.claude/config.minimal.json  .claude/
cp ~/.claude/config.balanced.json .claude/
cp ~/.claude/config.full.json     .claude/
cp ~/.claude/config.tdd.json      .claude/
cp ~/.claude/config.json          .claude/
cp ~/.claude/settings.json        .claude/

# ── Generate stack-specific CLAUDE.md ───────────────────────────
case "$STACK" in
    typescript)
        STACK_SECTION=$(cat << 'STACK'
## Stack
- Runtime:    Node.js 20 + TypeScript 5.x (strict mode)
- Framework:  Express 4 (or Next.js — update this)
- Database:   PostgreSQL via Prisma ORM
- Cache:      Redis (ioredis)
- Testing:    Vitest + supertest
- Lint:       ESLint + Prettier

## Architecture
- src/routes/        → Express route handlers (thin layer only)
- src/services/      → Business logic (fat layer)
- src/repositories/  → Database queries only
- src/types/         → Shared TypeScript interfaces
- tests/             → Mirror of src/ structure

## TypeScript Rules
1. NEVER use 'any' — use 'unknown' and narrow with type guards
2. All async functions must have try/catch or Result<T, E> type
3. Repository functions must NEVER contain business logic
4. Every exported function needs a corresponding unit test
STACK
)
        ;;
    python)
        STACK_SECTION=$(cat << 'STACK'
## Stack
- Runtime:    Python 3.12
- Framework:  FastAPI + Pydantic v2
- Database:   PostgreSQL via SQLAlchemy 2.0
- Testing:    pytest + httpx
- Lint:       ruff + mypy (strict)

## Architecture
- app/routes/     → FastAPI routers (thin layer only)
- app/services/   → Business logic
- app/models/     → SQLAlchemy models
- app/schemas/    → Pydantic schemas
- tests/          → Mirror of app/ structure

## Python Rules
1. All type hints required — mypy strict mode enforced
2. Never use print() in production — use the logger
3. All DB operations go through services, not routes
4. Every endpoint needs at least a happy-path integration test
STACK
)
        ;;
    fullstack)
        STACK_SECTION=$(cat << 'STACK'
## Stack
- Frontend:  React 18 + TypeScript + Tailwind CSS
- Backend:   Node.js 20 + Express + TypeScript
- Database:  PostgreSQL via Prisma
- Testing:   Vitest (unit) + Playwright (E2E)
- Build:     Vite (frontend) + tsc (backend)

## Architecture
- frontend/src/components/  → React components
- frontend/src/hooks/       → Custom hooks
- backend/src/routes/       → API routes
- backend/src/services/     → Business logic
- tests/                    → Unit + E2E tests

## Fullstack Rules
1. API contracts defined as shared TypeScript types in /shared
2. Frontend NEVER calls DB directly — always via API
3. All user-facing forms must have Zod validation (frontend + backend)
4. E2E tests cover all critical user journeys
STACK
)
        ;;
    *)
        STACK_SECTION=$(cat << 'STACK'
## Stack
[Fill in your stack details here]

## Architecture
[Describe your folder structure and module boundaries]

## Language Rules
[Add language/framework specific rules here]
STACK
)
        ;;
esac

cat > .claude/CLAUDE.md << EOF
# Project: $PROJECT

## Stage: IDEA
## Methodology: Agile
## Stack Type: $STACK

$STACK_SECTION

## Naming Conventions
- Files:      kebab-case (user-service.ts)
- Classes:    PascalCase (UserService)
- Functions:  camelCase (getUserById)
- Constants:  SCREAMING_SNAKE (MAX_RETRY_COUNT)
- DB tables:  snake_case (user_profiles)

## Coding Rules
1. Run tests before marking any task complete
2. Use /plan for any task touching more than 2 files
3. Preserve existing code style — read before writing
4. Never install packages without asking first
5. Never delete files without explicit confirmation
6. Update ## Stage as you progress through the lifecycle

## Custom Commands
/stage    → Show current lifecycle stage and next actions
/plan     → Step-by-step plan before acting (>2 files)
/next     → Advance to next lifecycle stage and update this file
/review   → Full code audit: types, logic, tests, security
/test     → Generate tests for the current file
/security → Run security vulnerability checklist
/docs     → Generate JSDoc / docstrings for exported functions
/effort   → Adjust reasoning depth for current task

## Do NOT
- Edit package-lock.json, yarn.lock, or poetry.lock directly
- Delete files without explicit user confirmation
- Push to main without passing tests
- Install packages without asking

## Current Stage
IDEA → next: SHAPE
EOF

# ── Create .gitignore ────────────────────────────────────────────
cat > .gitignore << 'EOF'
node_modules/
dist/
build/
.env
.env.local
*.log
.DS_Store
.cache/
coverage/
.claude/session-log.md
.claude/audit.log
__pycache__/
*.pyc
.venv/
EOF

echo ""
echo -e "${GREEN}✓ Project created: ${BOLD}$PROJECT_DIR${RESET}"
echo ""
echo -e "  Next steps:"
echo -e "  ${DIM}cd $PROJECT_DIR${RESET}"
echo -e "  ${DIM}ccb && claude${RESET}         # start with BALANCED mode"
echo -e "  ${DIM}cct && claude${RESET}         # or TDD mode for new modules"
echo ""
echo -e "  Inside Claude Code:"
echo -e "  ${DIM}> /stage${RESET}              # see your current lifecycle stage"
echo -e "  ${DIM}> /plan — describe your first feature${RESET}"
