#!/bin/bash
# Run this INSIDE the container: make enter -> bash /diagnose.sh
# Or from host: make diagnose

BOLD='\033[1m'; GREEN='\033[0;32m'; RED='\033[0;31m'
AMBER='\033[0;33m'; CYAN='\033[0;36m'; DIM='\033[2m'; RESET='\033[0m'

echo ""
echo -e "${BOLD}Claude Code — Network Diagnostics${RESET}"
echo "═══════════════════════════════════════"

pass() { echo -e "  ${GREEN}PASS${RESET}  $1"; }
fail() { echo -e "  ${RED}FAIL${RESET}  $1"; }
warn() { echo -e "  ${AMBER}WARN${RESET}  $1"; }
info() { echo -e "  ${DIM}INFO${RESET}  $1"; }

echo ""
echo -e "${BOLD}1. Basic internet${RESET}"
if curl -sf --max-time 5 https://example.com -o /dev/null 2>&1; then
  pass "General internet reachable"
else
  fail "Cannot reach internet at all"
  echo "     Fix: Docker Desktop -> Settings -> Resources -> Proxies"
fi

echo ""
echo -e "${BOLD}2. DNS resolution${RESET}"
if python3 -c "import socket; socket.getaddrinfo('api.anthropic.com', 443)" 2>/dev/null; then
  RESOLVED=$(python3 -c "import socket; print(socket.gethostbyname('api.anthropic.com'))" 2>/dev/null)
  pass "api.anthropic.com resolves to $RESOLVED"
else
  fail "Cannot resolve api.anthropic.com"
  echo "     Fix: add 'dns: [8.8.8.8]' to docker-compose.yml service"
fi

echo ""
echo -e "${BOLD}3. HTTPS reachability${RESET}"
HTTP_CODE=$(curl -sk --max-time 10 -o /dev/null -w "%{http_code}" https://api.anthropic.com 2>/dev/null)
CURL_EXIT=$?
if [ "$CURL_EXIT" -eq 0 ] && [ "$HTTP_CODE" != "000" ]; then
  pass "api.anthropic.com reachable (HTTP $HTTP_CODE)"
elif [ "$CURL_EXIT" -eq 7 ]; then
  fail "Connection refused / network unreachable"
  echo "     Likely cause: corporate firewall or VPN blocking port 443"
elif [ "$CURL_EXIT" -eq 60 ] || [ "$CURL_EXIT" -eq 35 ]; then
  warn "SSL error (HTTP $HTTP_CODE) — corporate proxy may be intercepting"
  echo "     Fix: add proxy env vars or corporate CA cert"
else
  fail "Cannot reach API (exit $CURL_EXIT, HTTP $HTTP_CODE)"
fi

echo ""
echo -e "${BOLD}4. Proxy environment${RESET}"
for VAR in http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY; do
  VAL="${!VAR}"
  if [ -n "$VAL" ]; then
    info "$VAR=$VAL"
  fi
done
if [ -z "$http_proxy$https_proxy$HTTP_PROXY$HTTPS_PROXY" ]; then
  warn "No proxy vars set in container"
  echo "     If your Mac uses a corporate proxy, add it to .env"
fi

echo ""
echo -e "${BOLD}5. Auth environment${RESET}"
if [ -n "$ANTHROPIC_API_KEY" ] && [[ "$ANTHROPIC_API_KEY" != *"YOUR_KEY"* ]]; then
  pass "ANTHROPIC_API_KEY is set"
elif [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
  pass "CLAUDE_CODE_OAUTH_TOKEN is set"
elif [ -n "$ANTHROPIC_AUTH_TOKEN" ]; then
  pass "ANTHROPIC_AUTH_TOKEN is set (gateway mode)"
elif [ -n "$CLAUDE_CODE_USE_BEDROCK" ]; then
  pass "Bedrock mode active"
elif [ -n "$CLAUDE_CODE_USE_VERTEX" ]; then
  pass "Vertex AI mode active"
elif [ -f "$HOME/.claude/.credentials.json" ] || [ -f "$HOME/.claude/credentials.json" ]; then
  pass "OAuth credentials file found"
else
  warn "No auth configured — run 'claude' to authenticate via browser"
fi

echo ""
echo -e "${BOLD}6. Quick connectivity test${RESET}"
VERBOSE=$(curl -sv --max-time 10 https://api.anthropic.com 2>&1 | head -30)
if echo "$VERBOSE" | grep -q "Connected to"; then
  pass "TCP connection established to api.anthropic.com:443"
elif echo "$VERBOSE" | grep -q "connect ECONNREFUSED\|Connection refused"; then
  fail "TCP connection refused"
elif echo "$VERBOSE" | grep -q "Could not resolve"; then
  fail "DNS failure"
elif echo "$VERBOSE" | grep -q "SSL certificate problem\|unable to get local issuer"; then
  warn "Corporate SSL interception detected (self-signed cert)"
  echo "     Fix: See proxy fix below"
fi

echo ""
echo "═══════════════════════════════════════"
echo -e "${BOLD}Suggested fix based on results above:${RESET}"
echo ""
if [ "$CURL_EXIT" -eq 7 ] || echo "$VERBOSE" | grep -q "Connection refused"; then
  echo -e "${AMBER}Network blocked — most likely causes:${RESET}"
  echo "  1. Corporate proxy not configured in Docker"
  echo "     -> Find your Mac proxy: scutil --proxy | grep -i proxy"
  echo "     -> Add to .env: HTTPS_PROXY=http://proxy.company.com:8080"
  echo "     -> Or: Docker Desktop -> Settings -> Resources -> Proxies"
  echo ""
  echo "  2. VPN is breaking Docker networking"
  echo "     -> Try: Docker Desktop -> Settings -> Network -> 'Use kernel networking'"
  echo "     -> Or: disconnect VPN, test, reconnect"
  echo ""
  echo "  3. Corporate firewall blocking port 443"
  echo "     -> Use Bedrock/Vertex instead of direct Anthropic API"
  echo "     -> See: make auth-help"
fi
echo ""
