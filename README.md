# Claude Code Development Sandbox

A ready-to-run Docker environment for AI-first software development. Clone, add your API key, and start building in under 5 minutes.

## Quick start

```bash
git clone https://github.com/YOUR_USERNAME/claude-dev-sandbox
cd claude-dev-sandbox

cp .env.example .env
# Edit .env → add your ANTHROPIC_API_KEY
# Get it from: https://console.anthropic.com/settings/keys

make check    # verify prerequisites
make start    # build image + start container (~3 min first time)
make enter    # open shell inside container

# Inside container:
new-project my-app typescript
cd /workspace/my-app
ccb && claude
```

## What's included

| Feature | Detail |
|---|---|
| Claude Code CLI | Latest version, authenticated via API key |
| 4 dev modes | MINIMAL · BALANCED · FULL · TDD |
| Hooks | Auto-lint · audit log · safety check · token metrics · session summary |
| Metrics | `make metrics` — token usage dashboard, per-tool breakdown |
| Project bootstrap | `new-project` — TypeScript, Python, fullstack, generic templates |
| Multi-agent support | `wt-add/wt-rm/wt-list` for git worktree workflows |
| VS Code Dev Containers | `.devcontainer/devcontainer.json` included |
| Mac local setup | `scripts/mac-setup.sh` for IntelliJ + native use |
| GitHub Actions | Auto-build and push to ghcr.io on merge |

## Dev modes

| Alias | Mode | Use when |
|---|---|---|
| `ccm` | MINIMAL | Small fix, rename, remove a line |
| `ccb` | BALANCED | New feature or endpoint ← **default** |
| `ccf` | FULL | Pre-PR review, architecture, security audit |
| `cct` | TDD | New module from scratch (Red→Green→Refactor) |

```bash
cc-mode        # show current mode
ccf && claude  # switch to FULL then start session
```

## Token metrics

```bash
make metrics           # usage dashboard (last 7 days)
make metrics-detail    # per-tool breakdown with timestamps
make metrics-today     # today only
make metrics-all       # full history

# Inside Claude Code session:
/cost                  # live running total
```

## Expose code to your Mac (for IDE access)

```bash
make mount     # set up ~/projects mount, then:
make restart   # apply it

# Now ~/projects/my-app on Mac = /workspace/my-app in container
# Open in IntelliJ or VS Code directly from Mac — same files, live
```

## Open in VS Code (attached to container)

```bash
make open                   # VS Code at /workspace
make open PROJECT=my-app    # VS Code at /workspace/my-app
```

Requires the VS Code **Dev Containers** extension.

## Export a project to Mac

```bash
make export PROJECT=my-app            # copies to ~/projects/my-app
make export PROJECT=my-app TO=~/Desktop
```

## Edit hooks and config

```bash
make edit-hooks                       # edit settings.json (hooks)
make edit-claude PROJECT=my-app       # edit project CLAUDE.md
make skills                           # list installed MCP plugins
```

## Mac local setup (for IntelliJ)

```bash
chmod +x scripts/mac-setup.sh && ./scripts/mac-setup.sh
# Then in IntelliJ: Plugins → search "Claude Code" → install "Claude Code [Beta]"
# Press Cmd+Esc to open Claude Code from anywhere in IntelliJ
```

## All make targets

```
make help            Show all targets
make build           Build Docker image from scratch
make start           Start sandbox
make stop            Stop (data preserved)
make restart         Stop + start
make enter           Open shell in container
make logs            Tail container logs
make status          Container status + active mode
make mode MODE=full  Switch mode from host
make open            Open VS Code attached to container
make export          Copy project to Mac
make mount           Set up host folder mount
make metrics         Token usage dashboard
make metrics-detail  Per-tool breakdown
make edit-hooks      Edit hooks (settings.json)
make edit-claude     Edit project CLAUDE.md
make skills          List MCP plugins
make rebuild         Force full rebuild
make clean           Remove container + image
make purge           Remove everything including volumes
make check           Verify prerequisites
```

## Project lifecycle (CLAUDE.md stages)

```
IDEA → SHAPE → PLAN → BUILD → TEST → REVIEW → DEPLOY → MONITOR
```

Use `/next` inside Claude Code to advance stages. Claude reads `## Stage` in CLAUDE.md and orients itself automatically every session.

## Repository structure

```
claude-dev-sandbox/
├── Dockerfile
├── docker-compose.yml
├── docker-compose.override.yml.example  ← copy + edit for host mount
├── Makefile
├── .env.example
├── .gitignore
├── README.md
├── .claude/
│   ├── settings.json          ← hooks: audit, lint, metrics, safety
│   ├── config.minimal.json
│   ├── config.balanced.json
│   ├── config.full.json
│   ├── config.tdd.json
│   └── CLAUDE.md.template
├── config/
│   └── zshrc                  ← aliases, help-claude, wt-* functions
├── scripts/
│   ├── docker-entrypoint.sh
│   ├── switch-mode.sh
│   ├── new-project.sh
│   ├── install-plugins.sh
│   ├── metrics-hook.py        ← logs per-tool metrics
│   ├── metrics.py             ← usage dashboard
│   └── mac-setup.sh           ← local Mac install (for IntelliJ)
├── .devcontainer/
│   └── devcontainer.json      ← VS Code Dev Containers config
└── .github/
    └── workflows/
        └── docker-build.yml   ← build + push to ghcr.io
```
