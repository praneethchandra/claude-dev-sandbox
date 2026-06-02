#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# switch-mode.sh — toggle between Claude Code dev modes
# Usage: switch-mode [minimal|balanced|full|tdd|show]
# ─────────────────────────────────────────────────────────────────

MODE="$1"
CLAUDE_DIR="$HOME/.claude"
ACTIVE="$CLAUDE_DIR/config.json"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

get_mode() {
    python3 -c "import json; d=json.load(open('$ACTIVE')); print(d.get('mode','unknown'))" 2>/dev/null
}

case "$MODE" in
    show|"")
        echo -e "Current mode: ${BOLD}$(get_mode)${RESET}"
        ;;
    minimal|balanced|full|tdd)
        CONFIG="$CLAUDE_DIR/config.$MODE.json"
        if [ ! -f "$CONFIG" ]; then
            echo -e "${RED}✗ Config not found: $CONFIG${RESET}"
            exit 1
        fi
        cp "$CONFIG" "$ACTIVE"
        NAME=$(get_mode)
        echo -e "${GREEN}✓ Mode: ${BOLD}$NAME${RESET}"
        ;;
    *)
        echo -e "${RED}✗ Unknown mode: $MODE${RESET}"
        echo -e "  Available: ${CYAN}minimal  balanced  full  tdd  show${RESET}"
        exit 1
        ;;
esac
