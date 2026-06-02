#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# install-plugins.sh — install recommended Claude Code MCP plugins
# Run once after container first boot.
# Usage: install-plugins [all|frontend|github|minimal]
# ─────────────────────────────────────────────────────────────────

PROFILE="${1:-minimal}"
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${CYAN}Installing plugins (profile: ${BOLD}$PROFILE${RESET}${CYAN})…${RESET}"
echo ""

install_plugin() {
    NAME="$1"
    echo -e "  Installing ${BOLD}$NAME${RESET}…"
    claude plugin install "$NAME" 2>/dev/null && \
        echo -e "  ${GREEN}✓ $NAME${RESET}" || \
        echo -e "  (skipped — may need active Claude session)"
}

case "$PROFILE" in
    minimal)
        echo "Minimal profile: frontend-design only"
        install_plugin "frontend-design"
        ;;
    frontend)
        install_plugin "frontend-design"
        install_plugin "github"
        ;;
    all)
        install_plugin "frontend-design"
        install_plugin "github"
        install_plugin "postgres"
        install_plugin "linear"
        ;;
    *)
        echo "Usage: install-plugins [minimal|frontend|all]"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✓ Done. Check installed plugins with: /plugin${RESET}"
echo -e "  Or list: ${BOLD}claude plugin list${RESET}"
