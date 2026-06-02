#!/bin/bash
# mac-setup.sh — install Claude Code + configs on your Mac (for IntelliJ / local use)
# Usage: chmod +x scripts/mac-setup.sh && ./scripts/mac-setup.sh
set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; AMBER='\033[0;33m'; BOLD='\033[1m'; RESET='\033[0m'
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo -e "\n${BOLD}Claude Code - Mac Local Setup${RESET}\n"

command -v brew &>/dev/null || \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo -e "${GREEN}Homebrew ready${RESET}"

node -v 2>/dev/null | grep -qE 'v(1[89]|[2-9][0-9])' || brew install node
echo -e "${GREEN}Node.js $(node --version)${RESET}"

npm install -g @anthropic-ai/claude-code
echo -e "${GREEN}Claude Code $(claude --version 2>/dev/null | head -1)${RESET}"

mkdir -p ~/.claude ~/bin
for cfg in minimal balanced full tdd; do
  cp "$REPO_DIR/.claude/config.$cfg.json" ~/.claude/
done
[ -f ~/.claude/settings.json ] || cp "$REPO_DIR/.claude/settings.json" ~/.claude/
cp "$REPO_DIR/.claude/CLAUDE.md.template" ~/.claude/
cp ~/.claude/config.balanced.json ~/.claude/config.json
echo -e "${GREEN}Configs synced to ~/.claude/${RESET}"

for s in switch-mode new-project install-plugins; do
  cp "$REPO_DIR/scripts/$s.sh" ~/bin/$s && chmod +x ~/bin/$s
done
echo -e "${GREEN}Scripts installed to ~/bin/${RESET}"

grep -q "Claude Code Aliases" ~/.zshrc 2>/dev/null || cat >> ~/.zshrc << 'ZSHEOF'

# Claude Code Aliases
export PATH="$HOME/bin:$PATH"
alias ccm='switch-mode minimal'
alias ccb='switch-mode balanced'
alias ccf='switch-mode full'
alias cct='switch-mode tdd'
alias cc-mode='switch-mode show'
alias ncp='new-project'
wt-add() { git worktree add "$2" "$1"; }
wt-rm()  { git worktree remove "$1"; }
wt-list(){ git worktree list; }
ZSHEOF
echo -e "${GREEN}Aliases added to ~/.zshrc${RESET}"

echo -e "\n${GREEN}${BOLD}Mac setup complete!${RESET}"
echo -e "  source ~/.zshrc"
echo -e "  IntelliJ: Plugins -> 'Claude Code [Beta]' -> Cmd+Esc"
echo -e "  VS Code:  Cmd+Shift+P -> 'Reopen in Container'"
echo -e "\n  For auth: claude  (browser OAuth - works with corporate account)\n"
