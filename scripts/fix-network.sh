#!/bin/bash
# fix-network.sh — auto-detects and fixes the most common Docker network issues
# Run from your Mac (NOT inside the container): bash scripts/fix-network.sh

BOLD='\033[1m'; GREEN='\033[0;32m'; RED='\033[0;31m'
AMBER='\033[0;33m'; CYAN='\033[0;36m'; DIM='\033[2m'; RESET='\033[0m'
ENV_FILE="$(dirname "$0")/../.env"

pass() { echo -e "  ${GREEN}✓${RESET} $1"; }
fail() { echo -e "  ${RED}✗${RESET} $1"; }
warn() { echo -e "  ${AMBER}!${RESET} $1"; }
sep()  { echo -e "\n${BOLD}$1${RESET}"; }

echo ""
echo -e "${BOLD}Claude Code — Network Fix Script${RESET}"
echo "════════════════════════════════════════"

# ─── PHASE 1: Mac-side tests ──────────────────────────────────────
sep "Phase 1: Mac connectivity (outside Docker)"

if curl -sf --max-time 8 https://api.anthropic.com -o /dev/null 2>&1; then
  pass "Mac can reach api.anthropic.com directly"
  MAC_OK=true
else
  fail "Mac CANNOT reach api.anthropic.com"
  MAC_OK=false
  warn "This is a Mac-level network issue (VPN, firewall, or proxy)"
fi

# Detect Mac proxy
HTTP_PROXY_MAC=$(networksetup -getwebproxy Wi-Fi 2>/dev/null | awk '/Server/{s=$2} /Port/{p=$2} END{if(s && s!="(null)") print "http://"s":"p}')
HTTPS_PROXY_MAC=$(networksetup -getsecurewebproxy Wi-Fi 2>/dev/null | awk '/Server/{s=$2} /Port/{p=$2} END{if(s && s!="(null)") print "http://"s":"p}')
SCUTIL_PROXY=$(scutil --proxy 2>/dev/null | awk '/HTTPSProxy/{p=$3} /HTTPSPort/{port=$3} END{if(p) print "http://"p":"port}')
PROXY="${HTTPS_PROXY_MAC:-$SCUTIL_PROXY}"

if [ -n "$PROXY" ]; then
  pass "Corporate proxy detected: $PROXY"
  PROXY_FOUND=true
else
  warn "No system proxy detected on Mac"
  PROXY_FOUND=false
fi

# ─── PHASE 2: Docker container tests ─────────────────────────────
sep "Phase 2: Docker container connectivity"

if ! docker ps --filter name=claude-dev --format '{{.Names}}' 2>/dev/null | grep -q claude-dev; then
  warn "Container not running — starting it..."
  docker compose up -d 2>/dev/null || { fail "Could not start container"; exit 1; }
  sleep 3
fi

# Basic DNS
if docker exec claude-dev nslookup api.anthropic.com >/dev/null 2>&1; then
  RESOLVED=$(docker exec claude-dev nslookup api.anthropic.com 2>/dev/null | awk '/Address/ && !/127.0.0/ {print $2; exit}')
  pass "DNS resolves api.anthropic.com → $RESOLVED"
  DNS_OK=true
else
  fail "DNS cannot resolve api.anthropic.com inside container"
  DNS_OK=false
fi

# Basic internet
if docker exec claude-dev curl -sf --max-time 8 https://example.com -o /dev/null 2>&1; then
  pass "Container has general internet access"
  NET_OK=true
else
  fail "Container has NO internet access at all"
  NET_OK=false
fi

# Anthropic API specifically
CURL_CODE=$(docker exec claude-dev curl -s --max-time 8 -o /dev/null -w "%{http_code}" https://api.anthropic.com 2>/dev/null)
CURL_EXIT=$?
if [ "$CURL_CODE" != "000" ] && [ $CURL_EXIT -ne 7 ]; then
  pass "Container can reach api.anthropic.com (HTTP $CURL_CODE)"
  API_OK=true
else
  fail "Container CANNOT reach api.anthropic.com (exit=$CURL_EXIT code=$CURL_CODE)"
  API_OK=false
fi

# ─── PHASE 3: Diagnose and fix ────────────────────────────────────
sep "Phase 3: Diagnosis and fix"

if $API_OK; then
  pass "Network is fine — the issue is likely authentication"
  echo ""
  echo "  Run: make auth-help"
  echo "  Or:  make enter → type: claude"
  exit 0
fi

if ! $NET_OK && ! $DNS_OK; then
  echo ""
  warn "Container has no internet at all. Likely causes:"
  echo ""
  echo -e "  ${BOLD}Fix A — Docker Desktop proxy settings (most common on corporate Mac):${RESET}"
  echo "  1. Open Docker Desktop"
  echo "  2. Settings → Resources → Proxies"
  echo "  3. Turn on 'Manual proxy configuration'"
  if [ -n "$PROXY" ]; then
    echo "  4. Set HTTP and HTTPS proxy to: $PROXY"
  else
    echo "  4. Enter your corporate proxy address"
  fi
  echo "  5. Apply & Restart Docker Desktop"
  echo "  6. make rebuild  (re-runs npm install through proxy)"
  echo ""
  echo -e "  ${BOLD}Fix B — VPN is blocking Docker:${RESET}"
  echo "  - Docker Desktop → Settings → Network → Enable 'Use kernel networking for UDP'"
  echo "  - Or: disconnect VPN, test, reconnect"
  echo "  - Or: ask IT for VPN split-tunnelling (exclude Docker subnets)"
  echo ""

elif $NET_OK && ! $API_OK && $PROXY_FOUND; then
  echo ""
  warn "Container has internet but can't reach Anthropic — proxy not configured in container."
  echo ""

  # Auto-write proxy to .env
  if [ -f "$ENV_FILE" ]; then
    if grep -q "^HTTPS_PROXY=" "$ENV_FILE"; then
      # Update existing
      sed -i.bak "s|^HTTPS_PROXY=.*|HTTPS_PROXY=$PROXY|" "$ENV_FILE"
      sed -i.bak "s|^HTTP_PROXY=.*|HTTP_PROXY=$PROXY|" "$ENV_FILE"
    else
      # Append
      echo "" >> "$ENV_FILE"
      echo "# Corporate proxy (auto-detected by fix-network.sh)" >> "$ENV_FILE"
      echo "HTTPS_PROXY=$PROXY" >> "$ENV_FILE"
      echo "HTTP_PROXY=$PROXY" >> "$ENV_FILE"
      echo "NO_PROXY=localhost,127.0.0.1" >> "$ENV_FILE"
    fi
    pass "Written to .env: HTTPS_PROXY=$PROXY"
    echo ""
    echo "  Restarting container with proxy settings..."
    docker compose restart 2>/dev/null
    sleep 4
    NEW_CODE=$(docker exec claude-dev curl -s --max-time 8 -o /dev/null -w "%{http_code}" https://api.anthropic.com 2>/dev/null)
    if [ "$NEW_CODE" != "000" ]; then
      pass "Fixed! api.anthropic.com now reachable (HTTP $NEW_CODE)"
      echo ""
      echo -e "  ${GREEN}Now run: make auth-help${RESET}"
    else
      fail "Still failing after proxy config. The proxy may require a corporate CA cert."
      echo ""
      echo "  See: make ssl-help"
    fi
  else
    warn ".env not found at $ENV_FILE"
    echo "  Create it: cp .env.example .env"
    echo "  Add: HTTPS_PROXY=$PROXY"
    echo "       HTTP_PROXY=$PROXY"
    echo "       NO_PROXY=localhost,127.0.0.1"
  fi

elif $NET_OK && ! $API_OK && ! $PROXY_FOUND; then
  echo ""
  warn "Container has internet but api.anthropic.com specifically is blocked."
  echo "  Possible causes:"
  echo "  - Corporate firewall blocking api.anthropic.com"
  echo "  - DNS returning wrong IP (DNS poisoning by corporate filter)"
  echo ""
  echo -e "  ${BOLD}Option 1 — Use AWS Bedrock or Google Vertex (bypass Anthropic entirely):${RESET}"
  echo "  Add to .env: CLAUDE_CODE_USE_BEDROCK=1 + AWS credentials"
  echo "  See: make auth-help"
  echo ""
  echo -e "  ${BOLD}Option 2 — Use internal LLM gateway (ask IT):${RESET}"
  echo "  Add to .env: ANTHROPIC_BASE_URL=https://your-internal-gateway.com"
  echo "               ANTHROPIC_AUTH_TOKEN=your-token"
  echo ""
  echo -e "  ${BOLD}Option 3 — Run Claude Code directly on Mac (skip Docker for auth):${RESET}"
  echo "  npm install -g @anthropic-ai/claude-code"
  echo "  claude    ← authenticates via browser on Mac natively"
fi

echo ""
