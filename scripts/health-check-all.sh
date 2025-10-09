#!/bin/bash

# Health Check All MCP Services
# Tests health endpoints for all deployed MCP servers
# Run this ON THE VM

echo "========================================"
echo "MCP Services Health Check"
echo "========================================"
echo ""

# Define services (name:port)
services=(
  "n8n-mcp:3000"
  "clickup-mcp:3002"
  "notion-mcp:3003"
  "google-workspace-mcp:3004"
  "github-mcp:3005"
)

# Colors for output (if terminal supports)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track results
total=0
passing=0
failing=0
skipped=0

echo "Local Health Checks (http://localhost):"
echo "----------------------------------------"

for service in "${services[@]}"; do
  IFS=':' read -r name port <<< "$service"
  total=$((total + 1))

  printf "%-25s port %-6s " "$name" "$port"

  # Check if port is listening
  if ! sudo lsof -i :$port &>/dev/null; then
    echo -e "${YELLOW}⏭️  SKIP${NC} (not running)"
    skipped=$((skipped + 1))
    continue
  fi

  # Perform health check
  response=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:$port/health 2>/dev/null || echo "000")

  if [ "$response" = "200" ] || [ "$response" = "204" ]; then
    echo -e "${GREEN}✅ OK${NC} (HTTP $response)"
    passing=$((passing + 1))
  else
    echo -e "${RED}❌ FAIL${NC} (HTTP $response)"
    failing=$((failing + 1))
  fi
done

echo ""
echo "Summary:"
echo "--------"
echo "Total services: $total"
echo -e "${GREEN}Passing: $passing${NC}"
echo -e "${RED}Failing: $failing${NC}"
echo -e "${YELLOW}Skipped: $skipped${NC}"
echo ""

# Test external endpoints if requested
if [ "$1" = "--external" ]; then
  echo "========================================"
  echo "External Health Checks (HTTPS)"
  echo "========================================"
  echo ""

  domains=(
    "n8n-mcp.aboundtechology.com"
    "clickup-mcp.aboundtechology.com"
    "notion-mcp.aboundtechology.com"
    "google-workspace-mcp.aboundtechology.com"
    "github-mcp.aboundtechology.com"
  )

  ext_total=0
  ext_passing=0
  ext_failing=0

  for domain in "${domains[@]}"; do
    ext_total=$((ext_total + 1))

    printf "%-40s " "$domain"

    response=$(curl -sf -o /dev/null -w "%{http_code}" https://$domain/health 2>/dev/null || echo "000")

    if [ "$response" = "200" ] || [ "$response" = "204" ]; then
      echo -e "${GREEN}✅ OK${NC} (HTTP $response)"
      ext_passing=$((ext_passing + 1))
    else
      echo -e "${RED}❌ FAIL${NC} (HTTP $response)"
      ext_failing=$((ext_failing + 1))
    fi
  done

  echo ""
  echo "External Summary:"
  echo "-----------------"
  echo "Total domains: $ext_total"
  echo -e "${GREEN}Passing: $ext_passing${NC}"
  echo -e "${RED}Failing: $ext_failing${NC}"
  echo ""
fi

# Exit with error if any failures
if [ $failing -gt 0 ]; then
  echo "⚠️  Some services are not healthy"
  echo "   Check logs: sudo journalctl -u <service-name> -n 50"
  exit 1
else
  if [ $skipped -eq $total ]; then
    echo "⚠️  No services are running"
    exit 1
  else
    echo "✅ All running services are healthy"
    exit 0
  fi
fi
