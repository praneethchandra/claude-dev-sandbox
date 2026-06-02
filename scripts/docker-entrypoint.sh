#!/bin/bash
set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; AMBER='\033[0;33m'
RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo -e "${RED}ERROR: ANTHROPIC_API_KEY is not set.${RESET}"
  echo "  Add it to your .env file and run: make restart"
  exit 1
fi

if [[ "$ANTHROPIC_API_KEY" == *"YOUR_KEY_HERE"* ]]; then
  echo -e "${AMBER}WARN: Placeholder API key detected in .env${RESET}"
  echo "  Replace it with your real key from console.anthropic.com"
  exit 1
fi

CLAUDE_DIR="$HOME/.claude"
if [ ! -f "$CLAUDE_DIR/config.balanced.json" ]; then
  echo -e "${CYAN}First boot: restoring Claude config…${RESET}"
  cp -r /tmp/claude-defaults/. "$CLAUDE_DIR/" 2>/dev/null || true
fi

[ -f "$CLAUDE_DIR/config.json" ] || cp "$CLAUDE_DIR/config.balanced.json" "$CLAUDE_DIR/config.json"

CURRENT_MODE=$(python3 -c \
  "import json; d=json.load(open('$CLAUDE_DIR/config.json')); print(d.get('mode','BALANCED'))" \
  2>/dev/null || echo "BALANCED")
CLAUDE_VERSION=$(claude --version 2>/dev/null | head -1 || echo "unknown")

echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║     Claude Code Development Sandbox          ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${DIM}Claude Code:${RESET}  ${BOLD}${CLAUDE_VERSION}${RESET}"
echo -e "  ${DIM}Active mode:${RESET}  ${BOLD}${CURRENT_MODE}${RESET}"
echo -e "  ${DIM}Model:       ${RESET}  ${BOLD}${ANTHROPIC_MODEL:-claude-sonnet-4-6}${RESET}"
echo -e "  ${DIM}Workspace:   ${RESET}  ${BOLD}/workspace${RESET}"
echo ""
echo -e "  ${BOLD}Quick start:${RESET}  new-project myapp typescript"
echo -e "                cd /workspace/myapp && ccb && claude"
echo -e "  ${BOLD}Help:${RESET}         help-claude"
echo ""

exec "$@"
