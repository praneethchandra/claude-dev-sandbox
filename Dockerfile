# ─────────────────────────────────────────────────────────────────
# Claude Code Development Sandbox
# Base: Node 20 LTS on Debian Bookworm slim
# Ships: Claude Code CLI, zsh, git, all mode configs, hooks, scripts
# ─────────────────────────────────────────────────────────────────
FROM node:20-bookworm-slim

LABEL org.opencontainers.image.title="Claude Code Dev Sandbox"
LABEL org.opencontainers.image.description="Full Claude Code development environment with multi-mode, hooks, multi-agent support"
LABEL org.opencontainers.image.source="https://github.com/YOUR_USERNAME/claude-dev-sandbox"

# ── System dependencies ──────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    zsh \
    python3 \
    python3-pip \
    jq \
    ripgrep \
    fzf \
    vim \
    nano \
    wget \
    unzip \
    sudo \
    ca-certificates \
    procps \
    less \
    && rm -rf /var/lib/apt/lists/*

# ── Install Claude Code globally ─────────────────────────────────
# Pin to a known-good version; bump in CI when you want to upgrade
ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} \
    && claude --version

# ── Oh My Zsh for a friendly shell ──────────────────────────────
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# ── Copy all Claude configs ──────────────────────────────────────
# These land in /root/.claude — the global Claude Code config dir
COPY .claude/                   /root/.claude/
COPY .claude/CLAUDE.md.template /root/.claude/CLAUDE.md.template

# ── Copy shell config ────────────────────────────────────────────
COPY config/zshrc               /root/.zshrc

# ── Copy scripts and put them on PATH ───────────────────────────
COPY scripts/                   /usr/local/claude-scripts/
RUN chmod +x /usr/local/claude-scripts/*.sh && \
    chmod +x /usr/local/claude-scripts/*.py 2>/dev/null || true

# Symlink scripts to PATH
RUN ln -sf /usr/local/claude-scripts/switch-mode.sh    /usr/local/bin/switch-mode && \
    ln -sf /usr/local/claude-scripts/new-project.sh    /usr/local/bin/new-project && \
    ln -sf /usr/local/claude-scripts/install-plugins.sh /usr/local/bin/install-plugins

# ── Git global config (avoids warnings on first run) ────────────
RUN git config --global init.defaultBranch main && \
    git config --global user.email "dev@claude-sandbox.local" && \
    git config --global user.name  "Claude Dev"

# ── Default active mode: BALANCED ───────────────────────────────
RUN cp /root/.claude/config.balanced.json /root/.claude/config.json

# ── Working directory for mounted projects ───────────────────────
WORKDIR /workspace

# ── Ports (optional — for dev servers running inside container) ──
EXPOSE 3000 3001 5173 8000 8080

ENTRYPOINT ["/usr/local/claude-scripts/docker-entrypoint.sh"]
CMD ["zsh"]

# ── Bake a defaults backup for volume first-boot restore ─────────
# When /root/.claude is a named volume, first boot is empty.
# The entrypoint copies from here if config files are missing.
RUN cp -r /root/.claude /tmp/claude-defaults
