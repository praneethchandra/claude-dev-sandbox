#!/bin/bash
PROFILE="${1:-minimal}"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

echo -e "${CYAN}Installing plugins (profile: ${BOLD}$PROFILE${RESET}${CYAN})${RESET}"

install_plugin() {
  echo -e "  Installing $1…"
  claude plugin install "$1" 2>/dev/null && echo -e "  ${GREEN}✓ $1${RESET}" || \
    echo -e "  (skipped — start a claude session first)"
}

case "$PROFILE" in
  minimal)  install_plugin "frontend-design" ;;
  frontend) install_plugin "frontend-design"; install_plugin "github" ;;
  all)      install_plugin "frontend-design"; install_plugin "github"
            install_plugin "postgres"; install_plugin "linear" ;;
  *)        echo "Usage: install-plugins [minimal|frontend|all]"; exit 1 ;;
esac

echo -e "${GREEN}Done. List plugins with: claude plugin list${RESET}"
