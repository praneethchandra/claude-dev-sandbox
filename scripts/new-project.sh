#!/bin/bash
PROJECT="$1"
STACK="${2:-typescript}"
WORKSPACE="/workspace"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

[ -n "$PROJECT" ] || { echo "Usage: new-project <name> [typescript|python|fullstack|generic]"; exit 1; }

PROJECT_DIR="$WORKSPACE/$PROJECT"
mkdir -p "$PROJECT_DIR/.claude"
cd "$PROJECT_DIR"

[ -d ".git" ] || { git init && git commit --allow-empty -m "chore: initial commit"; }

cp ~/.claude/config.*.json .claude/
cp ~/.claude/config.json .claude/
cp ~/.claude/settings.json .claude/

case "$STACK" in
  typescript)
    STACK_BLOCK="## Stack
- Runtime:   Node.js 20 + TypeScript 5.x (strict)
- Framework: Express 4 (update as needed)
- Database:  PostgreSQL via Prisma
- Testing:   Vitest + supertest
- Lint:      ESLint + Prettier

## Architecture
- src/routes/       Route handlers (thin)
- src/services/     Business logic (fat)
- src/repositories/ DB queries only
- src/types/        Shared interfaces
- tests/            Mirror of src/

## TypeScript Rules
1. Never use 'any' — use 'unknown' and narrow with type guards
2. All async functions must have try/catch or Result type
3. Every exported function needs a unit test"
    ;;
  python)
    STACK_BLOCK="## Stack
- Runtime:   Python 3.12
- Framework: FastAPI + Pydantic v2
- Database:  PostgreSQL via SQLAlchemy 2.0
- Testing:   pytest + httpx
- Lint:      ruff + mypy (strict)

## Architecture
- app/routes/   FastAPI routers (thin)
- app/services/ Business logic
- app/models/   SQLAlchemy models
- app/schemas/  Pydantic schemas
- tests/        Mirror of app/

## Python Rules
1. All type hints required — mypy strict mode
2. Never use print() — use the logger
3. Every endpoint needs a happy-path integration test"
    ;;
  fullstack)
    STACK_BLOCK="## Stack
- Frontend: React 18 + TypeScript + Tailwind CSS
- Backend:  Node.js 20 + Express + TypeScript
- Database: PostgreSQL via Prisma
- Testing:  Vitest (unit) + Playwright (E2E)

## Architecture
- frontend/src/components/
- frontend/src/hooks/
- backend/src/routes/
- backend/src/services/
- shared/types/ (shared TS types)
- tests/

## Rules
1. Shared types in /shared — never duplicated
2. Frontend never calls DB directly"
    ;;
  *)
    STACK_BLOCK="## Stack
[Fill in your stack details]

## Architecture
[Describe folder structure and module boundaries]"
    ;;
esac

cat > .claude/CLAUDE.md << EOF
# Project: $PROJECT

## Stage: IDEA
## Methodology: Agile
## Stack: $STACK

$STACK_BLOCK

## Naming Conventions
- Files: kebab-case | Classes: PascalCase | Functions: camelCase
- Constants: SCREAMING_SNAKE | DB tables: snake_case

## Rules
1. Run tests before marking any task complete
2. Use /plan for any task touching more than 2 files
3. Read existing code style before writing new code
4. Never install packages without asking
5. Never delete files without confirmation
6. Update ## Stage as you move through the lifecycle

## Custom Commands
/stage    -> Current lifecycle stage + next actions
/plan     -> Step-by-step plan before acting
/next     -> Advance to next lifecycle stage
/review   -> Full code audit
/test     -> Generate tests for current file
/security -> Security vulnerability checklist
/docs     -> Generate JSDoc / docstrings
/effort   -> Adjust reasoning depth

## Do NOT
- Edit lock files directly
- Delete files without confirmation
- Push to main without passing tests

## Current Stage
IDEA -> next: SHAPE
EOF

cat > .gitignore << 'GIEOF'
node_modules/
dist/
build/
.env
.env.local
*.log
.DS_Store
coverage/
.cache/
.claude/session-log.md
.claude/audit.log
.claude/metrics.jsonl
__pycache__/
*.pyc
.venv/
GIEOF

echo ""
echo -e "${GREEN}Project ready: ${BOLD}$PROJECT_DIR${RESET}"
echo -e "  cd $PROJECT_DIR && ccb && claude"
