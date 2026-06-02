# ─────────────────────────────────────────────────────────────────
# Claude Code Development Sandbox
# Base: Node 20 LTS on Debian Bookworm slim
# Ships: Claude Code CLI · zsh · git · 4 dev modes · hooks · metrics
# ─────────────────────────────────────────────────────────────────
FROM node:20-bookworm-slim

LABEL org.opencontainers.image.title="Claude Code Dev Sandbox"
LABEL org.opencontainers.image.description="Full Claude Code dev environment — modes, hooks, metrics, multi-agent"
LABEL org.opencontainers.image.source="https://github.com/YOUR_USERNAME/claude-dev-sandbox"

# ── System dependencies ──────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl zsh python3 python3-pip \
    jq ripgrep fzf vim nano wget unzip \
    sudo ca-certificates procps less xxd \
    && rm -rf /var/lib/apt/lists/*

# ── Install Claude Code globally ─────────────────────────────────
ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} \
    && claude --version

# ── Oh My Zsh ────────────────────────────────────────────────────
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# ── Copy Claude configs ──────────────────────────────────────────
COPY .claude/ /root/.claude/

# ── Copy shell config ─────────────────────────────────────────────
COPY config/zshrc /root/.zshrc

# ── Copy scripts onto PATH ────────────────────────────────────────
COPY scripts/ /usr/local/claude-scripts/
RUN chmod +x /usr/local/claude-scripts/*.sh \
    && chmod +x /usr/local/claude-scripts/*.py 2>/dev/null || true

RUN ln -sf /usr/local/claude-scripts/switch-mode.sh     /usr/local/bin/switch-mode  \
 && ln -sf /usr/local/claude-scripts/new-project.sh     /usr/local/bin/new-project  \
 && ln -sf /usr/local/claude-scripts/install-plugins.sh /usr/local/bin/install-plugins \
 && ln -sf /usr/local/claude-scripts/metrics.py         /usr/local/bin/metrics      \
 && ln -sf /usr/local/claude-scripts/metrics-hook.py    /usr/local/bin/metrics-hook

# ── Git global defaults ───────────────────────────────────────────
RUN git config --global init.defaultBranch main \
 && git config --global user.email "dev@claude-sandbox.local" \
 && git config --global user.name  "Claude Dev"

# ── Default active mode: BALANCED ────────────────────────────────
RUN cp /root/.claude/config.balanced.json /root/.claude/config.json

# ── Backup configs for first-boot volume restore ─────────────────
RUN cp -r /root/.claude /tmp/claude-defaults

WORKDIR /workspace

EXPOSE 3000 3001 5173 8000 8080

ENTRYPOINT ["/usr/local/claude-scripts/docker-entrypoint.sh"]
CMD ["zsh"]
