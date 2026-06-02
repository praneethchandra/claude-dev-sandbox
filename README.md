# Claude Code Development Sandbox 🚀

A ready-to-run Docker environment for AI-first software development with Claude Code. Clone, configure, and start building — no local Node.js or tool installation required.

## What's inside

| Feature | Detail |
|---|---|
| **Claude Code CLI** | Latest version, authenticated via API key |
| **4 Dev Modes** | MINIMAL · BALANCED · FULL · TDD (switch with `ccm/ccb/ccf/cct`) |
| **Hooks** | Auto-lint on write · audit log · safety checks · session summary |
| **Project bootstrap** | `new-project` script with TypeScript, Python, fullstack, generic templates |
| **Multi-agent support** | `wt-add/wt-rm/wt-list` aliases for git worktree management |
| **Shell** | zsh + Oh My Zsh · all aliases pre-loaded · `help-claude` command |
| **Lifecycle templates** | CLAUDE.md templates for all 8 stages (IDEA→SHAPE→PLAN→BUILD→TEST→REVIEW→DEPLOY→MONITOR) |

## Quick start

```bash
# 1. Clone
git clone https://github.com/YOUR_USERNAME/claude-dev-sandbox
cd claude-dev-sandbox

# 2. Add your API key
cp .env.example .env
nano .env   # paste your key: ANTHROPIC_API_KEY=sk-ant-api03-...

# 3. Start
make start

# 4. Enter the container
make enter

# 5. Create your first project (inside container)
new-project my-app typescript
cd /workspace/my-app
ccb && claude          # BALANCED mode + start coding
```

Get your API key at [console.anthropic.com](https://console.anthropic.com/settings/keys).

---

## Mounting your existing projects

By default, projects are stored in a Docker named volume (`claude-workspace`). To mount your host filesystem instead:

```bash
cp docker-compose.override.yml.example docker-compose.override.yml
nano docker-compose.override.yml   # change ~/projects to your path
make restart
```

Now files in `~/projects` on your machine appear at `/workspace` inside the container — and vice versa.

---

## Dev Modes

Switch modes before starting a Claude Code session:

| Alias | Mode | Use when |
|---|---|---|
| `ccm` | MINIMAL | Rename, small fix, remove a line |
| `ccb` | BALANCED | New feature, endpoint, component ← **default** |
| `ccf` | FULL | Pre-PR review, architecture audit, security |
| `cct` | TDD | New module from scratch (Red→Green→Refactor) |

```bash
cc-mode         # show current mode
ccf && claude   # switch to FULL then start session
```

---

## Hooks (automatic quality gates)

Hooks run automatically — you don't configure anything per-project.

| Event | What runs |
|---|---|
| Before every Bash command | Writes to audit log · flags dangerous commands |
| After every file write | Auto-runs ESLint fix on .ts/.tsx/.js/.jsx |
| After every file write | Re-runs matching test file |
| When Claude finishes | Appends `git diff --stat` to `.claude/session-log.md` |

Check the audit log any time:
```bash
cat ~/.claude/audit.log
cat .claude/session-log.md
```

---

## Claude Code slash commands (inside a session)

```
/stage      Show current lifecycle stage + next actions
/plan       Step-by-step plan before acting (>2 files)
/next       Advance to next lifecycle stage
/review     Full code audit: types, logic, tests, security
/test       Generate tests for current file
/security   Security vulnerability checklist
/docs       Generate JSDoc/docstrings
/effort     Adjust reasoning depth (low → xhigh)
/ultrareview [PR#]   Cloud parallel code review (May 2026)
/workflows  View dynamic workflow runs (May 2026)
/voice      Push-to-talk mode
/plugin     Manage MCP plugins
```

---

## Latest Claude features (May 2026)

### Dynamic Workflows *(Requires Max/Team/Enterprise plan)*
```
> "Create a dynamic workflow to audit every file in this
>  repo for security vulnerabilities"
/workflows   # monitor progress
```
Orchestrates 10–1,000 parallel subagents. Plan lives in a JS script, not the context window.

### Agent Teams *(Research preview, requires Opus 4.6)*
```
> /agents-team
```
Built-in coordination: team lead plans, spawns, assigns, and merges teammates' work.

### Auto Mode *(March 2026)*
```bash
claude --enable-auto-mode
# or: claude-auto (alias pre-loaded)
```
AI safety classifier auto-approves routine actions, only prompts when genuinely uncertain.

### Claude Design *(April 2026 — external tool)*
```
1. Open claude.ai/design
2. Describe UI → prototype generated
3. Export handoff bundle
4. In container: claude → "implement the handoff bundle"
```

### Effort Control
```
/effort           # interactive slider
/effort xhigh     # deep reasoning for hard problems
```

---

## Multi-agent workflow (git worktrees)

```bash
# Inside /workspace/my-project
wt-add feature/auth-system  /workspace/my-project-agent1
wt-add feature/add-tests    /workspace/my-project-agent2

# Open two more `make enter` terminals:
# Terminal 2: cd /workspace/my-project-agent1 && ccb && claude
# Terminal 3: cd /workspace/my-project-agent2 && cct && claude

# Merge when done
git merge feature/auth-system
git merge feature/add-tests

# Cleanup
wt-rm /workspace/my-project-agent1
wt-rm /workspace/my-project-agent2
```

---

## Makefile reference

```bash
make help       # all targets
make build      # build image from scratch
make start      # start container (build if needed)
make stop       # stop container (data preserved)
make restart    # stop + start
make enter      # open shell in running container
make logs       # tail container logs
make status     # container status + current mode
make mode MODE=full   # switch mode from host
make rebuild    # force full rebuild
make clean      # remove container + image (keeps volumes)
make purge      # remove everything including volumes ⚠️
make check      # verify prerequisites before first run
```

---

## Lifecycle stages (CLAUDE.md)

Update `## Stage` in your project's `.claude/CLAUDE.md` as you work. Claude reads this every session and orients itself accordingly.

```
IDEA → SHAPE → PLAN → BUILD → TEST → REVIEW → DEPLOY → MONITOR → (loops)
```

Use `/next` inside Claude Code to advance stages automatically.

---

## Project structure

```
claude-dev-sandbox/
├── Dockerfile                       ← Ubuntu + Node + Claude Code + zsh
├── docker-compose.yml               ← Service, volumes, env
├── docker-compose.override.yml.example  ← Host folder mount template
├── Makefile                         ← make start / make enter / etc.
├── .env.example                     ← Copy to .env, add API key
├── .gitignore
├── .claude/
│   ├── settings.json                ← Hooks (audit, lint, tests, stop)
│   ├── config.minimal.json          ← MINIMAL mode definition
│   ├── config.balanced.json         ← BALANCED mode definition
│   ├── config.full.json             ← FULL mode definition
│   ├── config.tdd.json              ← TDD mode definition
│   └── CLAUDE.md.template           ← Template for new projects
├── config/
│   └── zshrc                        ← Shell aliases + help-claude function
├── scripts/
│   ├── docker-entrypoint.sh         ← Container startup + banner
│   ├── switch-mode.sh               ← Mode switcher
│   ├── new-project.sh               ← Project bootstrap
│   └── install-plugins.sh           ← MCP plugin installer
└── .github/
    └── workflows/
        └── docker-build.yml          ← Build + push to ghcr.io on merge
```

---

## Updating Claude Code

```bash
# Rebuild the image to get the latest Claude Code version
make rebuild
```

Or pin to a specific version in `docker-compose.yml`:
```yaml
args:
  CLAUDE_CODE_VERSION: "2.1.154"
```

---

## Contributing

PRs welcome for new stack templates in `new-project.sh`, additional hooks in `settings.json`, or improvements to the mode configs.
