#!/bin/bash
# Supports all Claude Code auth methods — API key, OAuth token,
# browser OAuth, AWS Bedrock, Google Vertex AI, LLM gateway.
set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; AMBER='\033[0;33m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
CLAUDE_DIR="$HOME/.claude"

# First-boot: restore configs into named volume
if [ ! -f "$CLAUDE_DIR/config.balanced.json" ]; then
  echo -e "${CYAN}First boot: restoring Claude config...${RESET}"
  cp -r /tmp/claude-defaults/. "$CLAUDE_DIR/" 2>/dev/null || true
fi
[ -f "$CLAUDE_DIR/config.json" ] || cp "$CLAUDE_DIR/config.balanced.json" "$CLAUDE_DIR/config.json"

# Detect auth method
if [ -n "$CLAUDE_CODE_USE_BEDROCK" ]; then
  AUTH_METHOD="AWS Bedrock"
  AUTH_NOTE="Billing through your AWS account"
elif [ -n "$CLAUDE_CODE_USE_VERTEX" ]; then
  AUTH_METHOD="Google Vertex AI"
  AUTH_NOTE="Billing through your GCP account"
elif [ -n "$ANTHROPIC_AUTH_TOKEN" ]; then
  AUTH_METHOD="LLM Gateway (ANTHROPIC_AUTH_TOKEN)"
  AUTH_NOTE="${ANTHROPIC_BASE_URL:-https://api.anthropic.com}"
elif [ -n "$ANTHROPIC_API_KEY" ] && [[ "$ANTHROPIC_API_KEY" != *"YOUR_KEY_HERE"* ]]; then
  AUTH_METHOD="API Key"
  AUTH_NOTE="Direct Anthropic API"
elif [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
  AUTH_METHOD="OAuth Token"
  AUTH_NOTE="Corporate subscription token (no browser needed)"
elif [ -f "$CLAUDE_DIR/.credentials.json" ] || [ -f "$CLAUDE_DIR/credentials.json" ]; then
  AUTH_METHOD="OAuth (saved credentials)"
  AUTH_NOTE="From previous browser login - auto-refreshes"
else
  AUTH_METHOD="Not configured"
  AUTH_NOTE=""
fi

CURRENT_MODE=$(python3 -c "import json; d=json.load(open('$CLAUDE_DIR/config.json')); print(d.get('mode','BALANCED'))" 2>/dev/null || echo "BALANCED")
CLAUDE_VERSION=$(claude --version 2>/dev/null | head -1 || echo "unknown")

echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║     Claude Code Development Sandbox          ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${DIM}Claude Code:${RESET} ${BOLD}${CLAUDE_VERSION}${RESET}"
echo -e "  ${DIM}Auth:        ${RESET}${BOLD}${AUTH_METHOD}${RESET}  ${DIM}${AUTH_NOTE}${RESET}"
echo -e "  ${DIM}Mode:        ${RESET}${BOLD}${CURRENT_MODE}${RESET}"
echo -e "  ${DIM}Workspace:   ${RESET}${BOLD}/workspace${RESET}"
echo ""

if [ "$AUTH_METHOD" = "Not configured" ]; then
  echo -e "  ${AMBER}No auth configured. Options:${RESET}"
  echo ""
  echo -e "  ${BOLD}Option 1 - Browser login (run inside container):${RESET}"
  echo -e "  ${DIM}claude    <- shows a URL, open it in your Mac browser${RESET}"
  echo ""
  echo -e "  ${BOLD}Option 2 - Long-lived OAuth token (add to .env):${RESET}"
  echo -e "  ${DIM}CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-...${RESET}"
  echo ""
  echo -e "  ${BOLD}Option 3 - AWS Bedrock (add to .env):${RESET}"
  echo -e "  ${DIM}CLAUDE_CODE_USE_BEDROCK=1${RESET}"
  echo -e "  ${DIM}AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=...${RESET}"
  echo ""
  echo -e "  ${BOLD}Option 4 - Internal LLM gateway (add to .env):${RESET}"
  echo -e "  ${DIM}ANTHROPIC_BASE_URL=https://ai-gateway.company.com${RESET}"
  echo -e "  ${DIM}ANTHROPIC_AUTH_TOKEN=your-bearer-token${RESET}"
  echo ""
  echo -e "  Run: ${BOLD}make auth-help${RESET} for detailed instructions."
  echo ""
fi

echo -e "  ${DIM}Run ${BOLD}help-claude${DIM} for command reference${RESET}"
echo ""
exec "$@"
