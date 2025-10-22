#!/bin/bash
set -e

PROJECT_ID="abound-infr"
cd /opt/ai-agent-platform/mcp-servers/clickup-mcp

echo "Loading secrets from Google Secret Manager..."

# Fetch secrets to shell variables
CLICKUP_API_KEY=$(gcloud secrets versions access latest --secret="clickup-mcp-api-key" --project="$PROJECT_ID")
CLICKUP_TEAM_ID="90132011383"
PORT=3003

echo "Secrets loaded successfully"
echo "Starting ClickUp MCP server on port $PORT..."

# Start application using --env flags
exec npx -y @taazkareem/clickup-mcp-server@latest \
  --env CLICKUP_API_KEY=$CLICKUP_API_KEY \
  --env CLICKUP_TEAM_ID=$CLICKUP_TEAM_ID \
  --env PORT=$PORT \
  --env ENABLE_SSE=true \
  --env HOST=0.0.0.0 \
  --env NODE_ENV=production
