# ClickUp MCP Server - Configuration Updates

## ⚠️ Important Configuration Notes

After researching the actual `@taazkareem/clickup-mcp-server` package (v0.8.3), here are the key configuration details:

### Package-Specific Syntax

This package uses `--env` flags instead of shell environment variables:

```bash
# ✅ CORRECT - Package-specific syntax
npx -y @taazkareem/clickup-mcp-server@latest \
  --env CLICKUP_API_KEY=your-key \
  --env CLICKUP_TEAM_ID=your-team-id \
  --env PORT=3002 \
  --env ENABLE_SSE=true

# ❌ INCORRECT - Won't work with this package
export CLICKUP_API_KEY=your-key
npx -y @taazkareem/clickup-mcp-server@latest
```

### Default Configuration

- **Default Port:** 3231 (we're using custom port 3002)
- **Default Endpoints:**
  - Modern: `/mcp` (Streamable HTTP)
  - Legacy: `/sse` (Server-Sent Events)

### Required Environment Variables

- `CLICKUP_API_KEY` - From https://app.clickup.com/settings/apps
- `CLICKUP_TEAM_ID` - From workspace URL
- `PORT` - Custom port (optional, default 3231)
- `ENABLE_SSE` - Enable SSE transport (optional, default false)
- `HOST` - Bind address (optional, default likely 127.0.0.1)

### Updated load-secrets.sh

The correct script should pass environment variables using `--env` flags:

```bash
#!/bin/bash
set -e

PROJECT_ID="abound-infr"
cd /opt/ai-agent-platform/mcp-servers/clickup-mcp

echo "Loading secrets from Google Secret Manager..."

# Fetch secrets to shell variables
CLICKUP_API_KEY=$(gcloud secrets versions access latest --secret="clickup-mcp-api-key" --project="$PROJECT_ID")
CLICKUP_TEAM_ID="YOUR_TEAM_ID_HERE"
PORT=3002

echo "Secrets loaded successfully"
echo "Starting ClickUp MCP server on port $PORT..."

# Pass to npx using --env flags
exec npx -y @taazkareem/clickup-mcp-server@latest \
  --env CLICKUP_API_KEY=$CLICKUP_API_KEY \
  --env CLICKUP_TEAM_ID=$CLICKUP_TEAM_ID \
  --env PORT=$PORT \
  --env ENABLE_SSE=true \
  --env HOST=0.0.0.0 \
  --env NODE_ENV=production
```

### Testing After Research

1. ✅ Package exists and is actively maintained (v0.8.3)
2. ✅ Supports HTTP and SSE transports
3. ✅ Can run via npx (no global install needed)
4. ⚠️ Uses custom `--env` flag syntax (documented above)
5. ✅ Requires CLICKUP_API_KEY and CLICKUP_TEAM_ID

### Action Items

Need to update:
1. ✅ This notes file created
2. 🔜 Update `scripts/deploy-clickup.sh` with correct syntax
3. 🔜 Update `clickup/DEPLOYMENT.md` examples
4. 🔜 Test on VM to verify syntax works

## Verification Plan

Once deployed, verify:
1. Service starts without errors: `sudo journalctl -u clickup-mcp -n 50`
2. Health endpoint responds: `curl http://localhost:3002/health`
3. MCP endpoint on `/mcp`: `curl http://localhost:3002/mcp`
4. SSE endpoint (if enabled): `curl http://localhost:3002/sse`

## References

- GitHub: https://github.com/taazkareem/clickup-mcp-server
- NPM: https://www.npmjs.com/package/@taazkareem/clickup-mcp-server
- Latest Version: 0.8.3 (as of October 2025)
