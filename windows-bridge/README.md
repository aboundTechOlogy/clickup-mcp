# Windows Bridge for Claude Code Extension

This bridge allows the Claude Code extension in Cursor Windows to connect to the remote ClickUp-MCP server.

## Why is this needed?

Claude Code extension only supports stdio and SSE MCP server transports, not HTTP with bearer token authentication. This bridge converts stdio requests to HTTPS requests with proper authentication.

## Installation

### 1. Get Your Auth Token

On your local machine (with gcloud configured):

```bash
gcloud secrets versions access latest --secret=clickup-mcp-auth-token --project=abound-infr
```

Copy the token output.

### 2. Copy Bridge Script to Windows

Copy `clickup-mcp-bridge.js` to your Windows user directory:
```
C:\Users\<YourUsername>\clickup-mcp-bridge.js
```

### 3. Update the Bridge Script

Edit `C:\Users\<YourUsername>\clickup-mcp-bridge.js` and replace:
```javascript
const AUTH_TOKEN = 'YOUR_AUTH_TOKEN_HERE';
```

With your actual token:
```javascript
const AUTH_TOKEN = 'abc123xyz...'; // Paste token from step 1
```

### 4. Add Bridge to Claude Code

In PowerShell:
```powershell
claude mcp add clickup-mcp node C:\Users\<YourUsername>\clickup-mcp-bridge.js
```

### 5. Verify Connection

```powershell
claude mcp list
```

Should show:
```
clickup-mcp: node C:\Users\...\clickup-mcp-bridge.js - ✓ Connected
```

### 6. Restart Cursor

Restart Cursor Windows or start a new Claude Code chat session to use the ClickUp MCP tools.

---

## For WSL/Linux (Cursor WSL or Claude Code WSL)

You don't need the bridge script! Use direct HTTP configuration instead.

### Option A: Cursor WSL (Direct HTTP)

Edit `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "clickup-mcp": {
      "url": "https://clickup-mcp.aboundtechology.com/mcp",
      "transport": {
        "type": "http",
        "headers": {
          "Authorization": "Bearer YOUR_AUTH_TOKEN_HERE"
        }
      }
    }
  }
}
```

Get your token:
```bash
gcloud secrets versions access latest --secret=clickup-mcp-auth-token --project=abound-infr
```

### Option B: Claude Code WSL (Bridge Script)

If you want to use Claude Code chats in WSL, copy the bridge script to WSL:

1. Copy bridge script:
   ```bash
   cp ~/clickup-mcp/windows-bridge/clickup-mcp-bridge.js ~/clickup-mcp-bridge.js
   ```

2. Update AUTH_TOKEN in the file

3. Make executable:
   ```bash
   chmod +x ~/clickup-mcp-bridge.js
   ```

4. Add to Claude Code:
   ```bash
   claude mcp add clickup-mcp node ~/clickup-mcp-bridge.js
   ```

5. Verify:
   ```bash
   claude mcp list
   ```

---

## Troubleshooting

### Check the Log File

**Windows:**
```powershell
type $env:USERPROFILE\clickup-mcp-bridge.log
```

**WSL/Linux:**
```bash
cat ~/clickup-mcp-bridge.log
```

### Test Bridge Manually

**Windows:**
```powershell
echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}' | node C:\Users\<YourUsername>\clickup-mcp-bridge.js
```

**WSL/Linux:**
```bash
echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}' | node ~/clickup-mcp-bridge.js
```

Should return server info with all available ClickUp tools.

### Common Issues

**"Failed to parse response: Unexpected token"**
- The bridge couldn't parse the server's SSE response
- Check if the server URL is correct
- Verify server is deployed and running

**"Not Acceptable: Client must accept both application/json and text/event-stream"**
- The Accept header is missing (should be fixed in current version)

**"Connection refused"**
- Server is not running or not accessible
- Verify server is running:
  ```bash
  curl -H "Authorization: Bearer YOUR_TOKEN" https://clickup-mcp.aboundtechology.com/health
  ```

**"401 Unauthorized"**
- AUTH_TOKEN is incorrect or missing
- Get token again from Secret Manager

**"404 Not Found"**
- Wrong URL or server not deployed
- Check that Caddy proxy is configured correctly

---

## How It Works

```
Claude Code Extension (stdio)
    ↓
Bridge Script (stdio → HTTPS)
    ↓
ClickUp-MCP GCP Server (HTTPS + Bearer Token)
    ↓
ClickUp API
```

The bridge:
1. Listens on stdin for JSON-RPC messages from Claude Code
2. Forwards each request to the remote server via HTTPS POST
3. Handles SSE format responses from the server
4. Tracks session IDs for persistent connections
5. Returns JSON-RPC responses to Claude Code via stdout

---

## Multi-Environment Setup Summary

| Environment | Method | Configuration |
|-------------|--------|---------------|
| **Cursor WSL** | Direct HTTP | `~/.cursor/mcp.json` with HTTP transport |
| **Cursor Windows** | Direct HTTP | `C:\Users\<user>\.cursor\mcp.json` with HTTP transport |
| **Claude Code WSL** | Bridge Script | `claude mcp add clickup-mcp node ~/clickup-mcp-bridge.js` |
| **Claude Code Windows** | Bridge Script | `claude mcp add clickup-mcp node C:\Users\...\clickup-mcp-bridge.js` |
| **Claude Desktop** | TBD | Test after deployment (may need OAuth) |

---

## Security Notes

- **Never commit the auth token to git**
- The bridge script with token should remain on your local machine only
- Token is stored in Google Secret Manager on the server side
- Retrieve token only when needed using gcloud CLI
- Consider rotating tokens periodically

---

**Last Updated:** October 9, 2025
**Compatible with:** @taazkareem/clickup-mcp-server v0.8.3+
