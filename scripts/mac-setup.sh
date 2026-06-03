#!/bin/bash
set -e
GREEN='\033[0;32m'; BOLD='\033[1m'; RESET='\033[0m'
REPO="$(cd "$(dirname "$0")/.." && pwd)"
command -v brew &>/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
node -v 2>/dev/null | grep -qE 'v(1[89]|[2-9][0-9])' || brew install node
npm install -g @anthropic-ai/claude-code
mkdir -p ~/.claude ~/bin
for c in minimal balanced full tdd; do cp "$REPO/.claude/config.$c.json" ~/.claude/; done
[ -f ~/.claude/settings.json ] || cp "$REPO/.claude/settings.json" ~/.claude/
cp "$REPO/.claude/CLAUDE.md.template" ~/.claude/
cp ~/.claude/config.balanced.json ~/.claude/config.json
for s in switch-mode new-project install-plugins; do cp "$REPO/scripts/$s.sh" ~/bin/$s && chmod +x ~/bin/$s; done
grep -q "Claude Code Aliases" ~/.zshrc 2>/dev/null || cat >> ~/.zshrc << 'ZSH'
# Claude Code Aliases
export PATH="$HOME/bin:$PATH"
alias ccm='switch-mode minimal'; alias ccb='switch-mode balanced'
alias ccf='switch-mode full';    alias cct='switch-mode tdd'
alias cc-mode='switch-mode show'; alias ncp='new-project'
wt-add() { git worktree add "$2" "$1"; }; wt-rm() { git worktree remove "$1"; }
ZSH
echo -e "${GREEN}Done. source ~/.zshrc then: claude (browser auth)${RESET}"
