# ClickUp MCP OAuth Proxy

This OAuth 2.0 proxy wraps the ClickUp MCP server to enable Claude Desktop Custom Connectors without storing credentials in config files.

## Architecture

```
Claude Desktop
     ↓
[OAuth Proxy] :3001
  ↓ (validates OAuth token)
  ↓ (adds ClickUp auth)
[ClickUp MCP] :3002
```

## Features

- ✅ OAuth 2.0 with Dynamic Client Registration
- ✅ PKCE (Proof Key for Code Exchange)
- ✅ Token storage in SQLite
- ✅ Automatic token cleanup
- ✅ Session ID forwarding
- ✅ Health check endpoint

## Environment Variables

- `PROXY_PORT` - Port for OAuth proxy (default: 3001)
- `CLICKUP_MCP_URL` - URL of ClickUp MCP server (default: http://localhost:3002)
- `BASE_URL` - Public URL of this proxy (e.g., https://clickup-mcp.aboundtechology.com)
- `AUTH_TOKEN` - ClickUp MCP auth token (from Google Secret Manager)

## Deployment

See [../clickup/OAUTH_DEPLOYMENT.md](../clickup/OAUTH_DEPLOYMENT.md) for full deployment instructions.

## Local Development

```bash
npm install
npm run build
BASE_URL=http://localhost:3001 AUTH_TOKEN=your-token npm start
```

## OAuth Endpoints

- `/.well-known/oauth-authorization-server` - OAuth server metadata
- `/oauth/register` - Dynamic client registration
- `/oauth/authorize` - Authorization endpoint
- `/oauth/token` - Token exchange endpoint
- `/oauth/revoke` - Token revocation (optional)
- `/mcp` - MCP endpoint (with OAuth validation)
- `/health` - Health check

## Claude Desktop Setup

1. Open Claude Desktop
2. Settings → Connectors → Add Connector
3. Enter URL: `https://clickup-mcp.aboundtechology.com/mcp`
4. Claude will auto-discover OAuth and guide you through authorization
5. Done! No credentials in config files.
