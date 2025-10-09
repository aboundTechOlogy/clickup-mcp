# Client Setup Guide for ClickUp MCP Server

Complete guide for connecting all clients to your ClickUp MCP server on GCP.

## 🎯 Overview

Your ClickUp MCP server supports multiple connection methods:

| Client | Method | Setup Complexity |
|--------|--------|------------------|
| **Cursor WSL** | Direct HTTP | ⭐ Easy |
| **Cursor Windows** | Direct HTTP | ⭐ Easy |
| **Claude Desktop** | HTTP URL (OAuth in future) | ⭐⭐ Medium |
| **Claude Code WSL** | HTTP Transport via CLI | ⭐⭐ Medium |
| **Claude Code Windows** | HTTP Transport via CLI | ⭐⭐ Medium |

---

## 🔧 Method 1: Cursor (WSL & Windows) - Direct HTTP

**Best for:** Cursor IDE users who want the simplest setup

### Cursor WSL

1. Edit `~/.cursor/mcp.json`:
   ```bash
   nano ~/.cursor/mcp.json
   ```

2. Add ClickUp MCP configuration:
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

3. Get your auth token:
   ```bash
   gcloud secrets versions access latest --secret=clickup-mcp-auth-token --project=abound-infr
   ```

4. Replace `YOUR_AUTH_TOKEN_HERE` with the actual token

5. Restart Cursor WSL

### Cursor Windows

Same process, but edit:
```
C:\Users\<YourUsername>\.cursor\mcp.json
```

Then restart Cursor Windows.

---

## 🔧 Method 2: Claude Code (New CLI Method) - HTTP Transport

**Best for:** Claude Code users (introduced in 2025)

Claude Code now supports remote MCP servers directly via the CLI!

### Claude Code WSL

1. Get your auth token:
   ```bash
   gcloud secrets versions access latest --secret=clickup-mcp-auth-token --project=abound-infr
   ```

2. Add the server using the new HTTP transport:
   ```bash
   claude mcp add --transport http clickup-mcp https://clickup-mcp.aboundtechology.com/mcp
   ```

3. When prompted, authenticate using OAuth or provide the bearer token

4. Verify connection:
   ```bash
   claude mcp list
   ```

   Should show:
   ```
   clickup-mcp: https://clickup-mcp.aboundtechology.com/mcp - ✓ Connected
   ```

5. Start a new Claude Code chat to see ClickUp tools

### Claude Code Windows

Same commands in PowerShell:
```powershell
claude mcp add --transport http clickup-mcp https://clickup-mcp.aboundtechology.com/mcp
claude mcp list
```

---

## 🔧 Method 3: Claude Desktop - HTTP URL

**Best for:** Claude Desktop app users

### Option A: Direct HTTP URL (if supported)

1. Open Claude Desktop

2. Go to Settings → MCP Servers

3. Click "Add Server"

4. Configure:
   - **Name:** ClickUp MCP
   - **URL:** `https://clickup-mcp.aboundtechology.com/mcp`
   - **Auth Method:** Bearer Token
   - **Token:** (paste token from Secret Manager)

### Option B: OAuth (if ClickUp MCP supports it)

1. Check if server has OAuth endpoint:
   ```bash
   curl https://clickup-mcp.aboundtechology.com/.well-known/mcp-oauth
   ```

2. If yes, Claude Desktop will auto-discover OAuth and guide you through setup

3. OAuth callback URL is: `https://claude.ai/api/mcp/auth_callback`

### Testing

Ask Claude Desktop: "What ClickUp tools are available?"

Should see tools like:
- get_task
- create_task
- update_task
- search_tasks
- etc.

---

## 🔧 Method 4: Bridge Script (Fallback for older Claude Code)

**Only needed if:** Claude Code HTTP transport doesn't work for you

### Setup Windows Bridge

1. Copy bridge script:
   ```
   windows-bridge/clickup-mcp-bridge.js → C:\Users\<YourUsername>\clickup-mcp-bridge.js
   ```

2. Get auth token:
   ```bash
   gcloud secrets versions access latest --secret=clickup-mcp-auth-token --project=abound-infr
   ```

3. Edit `C:\Users\<YourUsername>\clickup-mcp-bridge.js`:
   ```javascript
   const AUTH_TOKEN = 'YOUR_ACTUAL_TOKEN_HERE';
   ```

4. Add to Claude Code:
   ```powershell
   claude mcp add clickup-mcp node C:\Users\<YourUsername>\clickup-mcp-bridge.js
   ```

5. Verify:
   ```powershell
   claude mcp list
   ```

### Setup WSL Bridge

1. Copy bridge script:
   ```bash
   cp ~/clickup-mcp/windows-bridge/clickup-mcp-bridge.js ~/clickup-mcp-bridge.js
   ```

2. Get auth token and update file

3. Make executable:
   ```bash
   chmod +x ~/clickup-mcp-bridge.js
   ```

4. Add to Claude Code:
   ```bash
   claude mcp add clickup-mcp node ~/clickup-mcp-bridge.js
   ```

See [windows-bridge/README.md](./windows-bridge/README.md) for full details.

---

## ✅ Verification

After setup, verify connection in each client:

### Cursor
1. Open MCP panel/settings
2. Should see "clickup-mcp" server listed
3. Ask: "What ClickUp tools are available?"

### Claude Code
1. Start new chat
2. Type `/mcp` to see menu
3. Should see "clickup-mcp" in server list
4. Ask: "List my ClickUp tasks"

### Claude Desktop
1. Check MCP settings
2. Should show "Connected" status
3. Ask: "What can you do with ClickUp?"

---

## 🔒 Security Best Practices

### Auth Token Management

1. **Never commit tokens to git**
   - User config files are gitignored by default
   - Bridge scripts should remain local only

2. **Retrieve tokens on-demand**
   ```bash
   # Get token when needed
   gcloud secrets versions access latest --secret=clickup-mcp-auth-token --project=abound-infr
   ```

3. **Rotate tokens periodically**
   ```bash
   # Generate new token
   echo -n "$(openssl rand -base64 32)" | \
     gcloud secrets versions add clickup-mcp-auth-token \
     --data-file=- \
     --project=abound-infr

   # Then update all client configs
   ```

4. **Use OAuth when available**
   - Claude Desktop supports OAuth 2.1
   - OAuth is more secure than bearer tokens
   - Tokens auto-refresh

---

## 🔍 Troubleshooting

### Connection Failed

**Test server is running:**
```bash
curl https://clickup-mcp.aboundtechology.com/health
```

Should return: `{"status":"ok"}` or similar

**Test with auth:**
```bash
TOKEN=$(gcloud secrets versions access latest --secret=clickup-mcp-auth-token --project=abound-infr)
curl -H "Authorization: Bearer $TOKEN" https://clickup-mcp.aboundtechology.com/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

Should return list of ClickUp tools.

### 401 Unauthorized

- Auth token is wrong or missing
- Get fresh token from Secret Manager
- Check for extra spaces or line breaks in token

### 404 Not Found

- Server not deployed or Caddy not configured
- Check server status: `sudo systemctl status clickup-mcp`
- Check Caddy logs: `docker logs n8n-proxy-caddy-1`

### No Tools Available

- Connection succeeded but tools not loading
- Check server logs: `sudo journalctl -u clickup-mcp -n 50`
- Verify CLICKUP_API_KEY and CLICKUP_TEAM_ID are set correctly

### Bridge Script Issues

Check bridge log:
```powershell
# Windows
type $env:USERPROFILE\clickup-mcp-bridge.log

# WSL
cat ~/clickup-mcp-bridge.log
```

---

## 📊 Connection Summary

After setup, you should have:

```
┌─────────────────────────────────────┐
│   Claude Desktop                    │
│   (HTTP URL or OAuth)               │──┐
└─────────────────────────────────────┘  │
                                         │
┌─────────────────────────────────────┐  │
│   Claude Code WSL                   │  │
│   (HTTP Transport via CLI)          │──┤
└─────────────────────────────────────┘  │
                                         │
┌─────────────────────────────────────┐  │    ┌─────────────────────────────┐
│   Claude Code Windows               │  ├───→│  ClickUp MCP GCP Server     │
│   (HTTP Transport via CLI)          │──┘    │  Port 3002                  │
└─────────────────────────────────────┘       │  https://clickup-mcp...     │
                                              └─────────────────────────────┘
┌─────────────────────────────────────┐              ↑
│   Cursor WSL                        │              │
│   (Direct HTTP)                     │──────────────┤
└─────────────────────────────────────┘              │
                                                     │
┌─────────────────────────────────────┐              │
│   Cursor Windows                    │              │
│   (Direct HTTP)                     │──────────────┘
└─────────────────────────────────────┘
```

---

## 🚀 Next Steps

Once connected:

1. **Test basic functionality:**
   - "List my ClickUp spaces"
   - "Show tasks in [workspace]"
   - "Create a test task"

2. **Explore available tools:**
   - `get_task` - Get task details
   - `create_task` - Create new tasks
   - `update_task` - Update existing tasks
   - `search_tasks` - Search across workspace
   - `create_comment` - Add task comments
   - `get_list`, `get_folder`, `get_space` - Navigate structure

3. **Build workflows:**
   - Automate task creation from conversations
   - Update tasks based on code changes
   - Search tasks for context
   - Add comments programmatically

---

## 📚 Additional Resources

- [DEPLOYMENT_PLAN_V2.md](./DEPLOYMENT_PLAN_V2.md) - Overall deployment strategy
- [clickup/DEPLOYMENT.md](./clickup/DEPLOYMENT.md) - Server deployment guide
- [windows-bridge/README.md](./windows-bridge/README.md) - Bridge script details
- [Claude Docs - MCP](https://docs.claude.com/en/docs/agents-and-tools/mcp-connector) - Official MCP documentation

---

**Last Updated:** October 9, 2025
**Server Version:** @taazkareem/clickup-mcp-server v0.8.3+
