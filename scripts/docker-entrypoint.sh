#!/bin/bash
set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; AMBER='\033[0;33m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
CLAUDE_DIR="$HOME/.claude"

# First-boot: restore configs into named volume
if [ ! -f "$CLAUDE_DIR/config.balanced.json" ]; then
  cp -r /tmp/claude-defaults/. "$CLAUDE_DIR/" 2>/dev/null || true
fi
[ -f "$CLAUDE_DIR/config.json" ] || \
  cp "$CLAUDE_DIR/config.balanced.json" "$CLAUDE_DIR/config.json"

# Detect active auth method — only the supported ones
if [ -n "$CLAUDE_CODE_USE_BEDROCK" ]; then
  AUTH="AWS Bedrock"
  NOTE="billing through AWS"
elif [ -n "$CLAUDE_CODE_USE_VERTEX" ]; then
  AUTH="Google Vertex AI"
  NOTE="billing through GCP"
elif [ -n "$ANTHROPIC_API_KEY" ] && [[ "$ANTHROPIC_API_KEY" != *"YOUR_KEY"* ]]; then
  AUTH="API Key"
  NOTE="direct Anthropic API"
elif [ -f "$CLAUDE_DIR/.credentials.json" ] || [ -f "$CLAUDE_DIR/credentials.json" ]; then
  AUTH="OAuth (saved)"
  NOTE="from browser login — auto-refreshes"
else
  AUTH="Not configured"
  NOTE="run 'claude' inside the container to sign in"
fi

MODE=$(python3 -c \
  "import json; d=json.load(open('$CLAUDE_DIR/config.json')); print(d.get('mode','BALANCED'))" \
  2>/dev/null || echo "BALANCED")
VER=$(claude --version 2>/dev/null | head -1 || echo "unknown")

echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║     Claude Code Development Sandbox          ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${DIM}Claude:${RESET} ${BOLD}${VER}${RESET}"
echo -e "  ${DIM}Auth:${RESET}   ${BOLD}${AUTH}${RESET}  ${DIM}${NOTE}${RESET}"
echo -e "  ${DIM}Mode:${RESET}   ${BOLD}${MODE}${RESET}"
[ -n "$HTTPS_PROXY" ] && \
  echo -e "  ${DIM}Proxy:${RESET}  ${BOLD}${HTTPS_PROXY}${RESET}"
echo ""

if [ "$AUTH" = "Not configured" ]; then
  echo -e "  ${AMBER}No auth set. Sign in:${RESET}"
  echo -e "  ${DIM}1. Type 'claude' → open the URL in your Mac browser${RESET}"
  echo -e "  ${DIM}2. Or add ANTHROPIC_API_KEY to .env then: make restart${RESET}"
  echo ""
fi

echo -e "  ${DIM}Network issues? Run on Mac: ${BOLD}bash scripts/fix-network.sh${RESET}"
echo -e "  ${DIM}Commands:                   ${BOLD}help-claude${RESET}"
echo ""
exec "$@"
