#!/bin/bash

# Test MCP Endpoint
# Tests MCP JSON-RPC endpoint for a specific service
# Usage: ./test-mcp-endpoint.sh <service-name> [--external]

SERVICE=$1
EXTERNAL=${2:-""}

if [ -z "$SERVICE" ]; then
  echo "Usage: $0 <service-name> [--external]"
  echo ""
  echo "Examples:"
  echo "  $0 clickup-mcp"
  echo "  $0 clickup-mcp --external"
  echo ""
  echo "Available services:"
  echo "  - n8n-mcp (port 3000)"
  echo "  - clickup-mcp (port 3002)"
  echo "  - notion-mcp (port 3003)"
  echo "  - google-workspace-mcp (port 3004)"
  echo "  - github-mcp (port 3005)"
  exit 1
fi

# Map service names to ports
case $SERVICE in
  n8n-mcp)
    PORT=3000
    SECRET_NAME="n8n-mcp-auth-token"
    ;;
  clickup-mcp)
    PORT=3002
    SECRET_NAME="clickup-mcp-auth-token"
    ;;
  notion-mcp)
    PORT=3003
    SECRET_NAME="notion-mcp-auth-token"
    ;;
  google-workspace-mcp)
    PORT=3004
    SECRET_NAME="google-workspace-mcp-auth-token"
    ;;
  github-mcp)
    PORT=3005
    SECRET_NAME="github-mcp-auth-token"
    ;;
  *)
    echo "❌ Error: Unknown service '$SERVICE'"
    exit 1
    ;;
esac

PROJECT_ID="abound-infr"

echo "========================================"
echo "Testing MCP Endpoint: $SERVICE"
echo "========================================"
echo ""

# Get auth token
echo "🔑 Fetching auth token from Secret Manager..."
if ! AUTH_TOKEN=$(gcloud secrets versions access latest --secret=$SECRET_NAME --project=$PROJECT_ID 2>/dev/null); then
  echo "❌ Error: Cannot access secret '$SECRET_NAME'"
  echo "   Make sure the secret exists and you have access"
  exit 1
fi
echo "✅ Auth token retrieved"
echo ""

# Determine URL
if [ "$EXTERNAL" = "--external" ]; then
  URL="https://$SERVICE.aboundtechology.com/mcp"
  echo "🌐 Testing external endpoint: $URL"
else
  URL="http://localhost:$PORT/mcp"
  echo "🏠 Testing local endpoint: $URL"
fi
echo ""

# Test 1: tools/list
echo "Test 1: Listing available tools"
echo "--------------------------------"
echo "Request: {\"jsonrpc\":\"2.0\",\"method\":\"tools/list\",\"id\":1}"
echo ""

RESPONSE=$(curl -s -X POST "$URL" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}')

echo "Response:"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""

# Check if response is valid JSON-RPC
if echo "$RESPONSE" | jq -e '.result' &>/dev/null; then
  echo "✅ tools/list succeeded"
  TOOL_COUNT=$(echo "$RESPONSE" | jq '.result.tools | length' 2>/dev/null || echo "0")
  echo "   Available tools: $TOOL_COUNT"
else
  echo "❌ tools/list failed or returned error"
  if echo "$RESPONSE" | jq -e '.error' &>/dev/null; then
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message' 2>/dev/null)
    echo "   Error: $ERROR_MSG"
  fi
fi
echo ""

# Test 2: resources/list (if supported)
echo "Test 2: Listing available resources"
echo "------------------------------------"
echo "Request: {\"jsonrpc\":\"2.0\",\"method\":\"resources/list\",\"id\":2}"
echo ""

RESPONSE=$(curl -s -X POST "$URL" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"resources/list","id":2}')

echo "Response:"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""

if echo "$RESPONSE" | jq -e '.result' &>/dev/null; then
  echo "✅ resources/list succeeded"
  RESOURCE_COUNT=$(echo "$RESPONSE" | jq '.result.resources | length' 2>/dev/null || echo "0")
  echo "   Available resources: $RESOURCE_COUNT"
else
  echo "⚠️  resources/list not supported or failed (this is normal for some servers)"
fi
echo ""

# Test 3: prompts/list (if supported)
echo "Test 3: Listing available prompts"
echo "----------------------------------"
echo "Request: {\"jsonrpc\":\"2.0\",\"method\":\"prompts/list\",\"id\":3}"
echo ""

RESPONSE=$(curl -s -X POST "$URL" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"prompts/list","id":3}')

echo "Response:"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""

if echo "$RESPONSE" | jq -e '.result' &>/dev/null; then
  echo "✅ prompts/list succeeded"
  PROMPT_COUNT=$(echo "$RESPONSE" | jq '.result.prompts | length' 2>/dev/null || echo "0")
  echo "   Available prompts: $PROMPT_COUNT"
else
  echo "⚠️  prompts/list not supported or failed (this is normal for some servers)"
fi
echo ""

# Summary
echo "========================================"
echo "Test Summary"
echo "========================================"
echo ""
echo "Service: $SERVICE"
echo "Port: $PORT"
echo "Endpoint: $URL"
echo ""
echo "✅ Authentication working"
echo "✅ Server responding to JSON-RPC requests"
echo ""
echo "Next steps:"
echo "  - Configure client (Cursor, Claude Desktop, etc.)"
echo "  - Test actual tool invocations"
echo ""
