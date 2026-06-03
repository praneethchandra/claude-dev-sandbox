FROM node:20-bookworm-slim

LABEL org.opencontainers.image.title="Claude Code Dev Sandbox"
LABEL org.opencontainers.image.source="https://github.com/YOUR_USERNAME/claude-dev-sandbox"

# Proxy build args — needed so npm install works on corporate networks
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
ENV HTTP_PROXY=${HTTP_PROXY} HTTPS_PROXY=${HTTPS_PROXY} \
    http_proxy=${HTTP_PROXY} https_proxy=${HTTPS_PROXY} \
    NO_PROXY=${NO_PROXY} no_proxy=${NO_PROXY}

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl zsh python3 python3-pip jq ripgrep fzf vim nano \
    wget unzip sudo ca-certificates procps less xxd dnsutils \
    && rm -rf /var/lib/apt/lists/*

ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} \
    && claude --version

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

COPY .claude/         /root/.claude/
COPY config/zshrc     /root/.zshrc
COPY scripts/         /usr/local/claude-scripts/

RUN chmod +x /usr/local/claude-scripts/*.sh \
    && chmod +x /usr/local/claude-scripts/*.py 2>/dev/null || true

RUN ln -sf /usr/local/claude-scripts/switch-mode.sh     /usr/local/bin/switch-mode  \
 && ln -sf /usr/local/claude-scripts/new-project.sh     /usr/local/bin/new-project  \
 && ln -sf /usr/local/claude-scripts/install-plugins.sh /usr/local/bin/install-plugins \
 && ln -sf /usr/local/claude-scripts/metrics.py         /usr/local/bin/metrics      \
 && ln -sf /usr/local/claude-scripts/metrics-hook.py    /usr/local/bin/metrics-hook \
 && ln -sf /usr/local/claude-scripts/diagnose.sh        /usr/local/bin/diagnose

RUN git config --global init.defaultBranch main \
 && git config --global user.email "dev@claude-sandbox.local" \
 && git config --global user.name  "Claude Dev"

RUN cp /root/.claude/config.balanced.json /root/.claude/config.json
RUN cp -r /root/.claude /tmp/claude-defaults

# Clear proxy at runtime — each container picks up from .env
ENV HTTP_PROXY="" HTTPS_PROXY="" http_proxy="" https_proxy=""

WORKDIR /workspace
EXPOSE 3000 3001 5173 8000 8080

ENTRYPOINT ["/usr/local/claude-scripts/docker-entrypoint.sh"]
CMD ["zsh"]
