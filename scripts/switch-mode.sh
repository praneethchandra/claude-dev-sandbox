#!/bin/bash
MODE="$1"
CLAUDE_DIR="$HOME/.claude"
ACTIVE="$CLAUDE_DIR/config.json"

get_mode() {
  python3 -c "import json; d=json.load(open('$ACTIVE')); print(d.get('mode','unknown'))" 2>/dev/null
}

case "$MODE" in
  show|"")
    echo "Current mode: $(get_mode)"
    ;;
  minimal|balanced|full|tdd)
    CONFIG="$CLAUDE_DIR/config.$MODE.json"
    [ -f "$CONFIG" ] || { echo "Config not found: $CONFIG"; exit 1; }
    cp "$CONFIG" "$ACTIVE"
    echo "Mode: $(get_mode)"
    ;;
  *)
    echo "Unknown mode: $MODE"
    echo "Available: minimal  balanced  full  tdd  show"
    exit 1
    ;;
esac
