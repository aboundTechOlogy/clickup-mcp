# Migration Guide: Bridge Script → HTTP Transport

## ⚠️ Important Discovery

**You DON'T need the bridge script anymore!**

Claude Code has supported HTTP transport directly since **June 2025**. The bridge script was created based on older patterns but is now unnecessary.

## For n8n-MCP Users

### Current Setup (Bridge Script)
```bash
claude mcp add n8n-mcp-gcp node C:\Users\dreww\n8n-mcp-bridge.js
```

### New Setup (Direct HTTP) - **RECOMMENDED**
```bash
TOKEN=$(gcloud secrets versions access latest --secret=n8n-mcp-auth-token --project=abound-infr)

claude mcp add -t http n8n-mcp-gcp https://n8n-mcp.aboundtechology.com/mcp \
  -H "Authorization: Bearer $TOKEN"
```

## For ClickUp-MCP Users

**Use HTTP transport from the start:**

```bash
TOKEN=$(gcloud secrets versions access latest --secret=clickup-mcp-auth-token --project=abound-infr)

claude mcp add -t http clickup-mcp https://clickup-mcp.aboundtechology.com/mcp \
  -H "Authorization: Bearer $TOKEN"
```

## Migration Steps

### 1. Remove Old Bridge-Based Server
```bash
# Check what you have
claude mcp list

# Remove bridge-based server
claude mcp remove n8n-mcp-gcp
```

### 2. Add Using HTTP Transport
```bash
# Get token
TOKEN=$(gcloud secrets versions access latest --secret=n8n-mcp-auth-token --project=abound-infr)

# Add with HTTP transport
claude mcp add -t http n8n-mcp https://n8n-mcp.aboundtechology.com/mcp \
  -H "Authorization: Bearer $TOKEN"
```

### 3. Verify Connection
```bash
claude mcp list
```

Should show:
```
n8n-mcp: https://n8n-mcp.aboundtechology.com/mcp (HTTP) - ✓ Connected
```

### 4. Test in Chat
Open a new Claude Code chat and ask: "What n8n tools are available?"

## Benefits of HTTP Transport

✅ **Simpler** - No bridge script to maintain
✅ **Faster** - Direct connection, no stdio overhead
✅ **Cleaner** - No intermediate Node.js process
✅ **Debuggable** - Better error messages from CLI
✅ **Standard** - Uses official Claude Code feature

## When to Keep Bridge Script

The bridge script is still useful for:
- ❌ None - HTTP transport is better in all cases!

## Comparison

| Method | Complexity | Performance | Maintenance |
|--------|------------|-------------|-------------|
| **HTTP Transport** | ⭐ Simple | ⚡ Fast | ✅ None |
| Bridge Script | ⭐⭐⭐ Complex | 🐌 Slower | ⚠️ High |

## Updated Architecture

### Before (Bridge Script)
```
Claude Code Extension
    ↓ stdio
Bridge Script (Node.js)
    ↓ HTTPS + Bearer Token
MCP Server (GCP)
```

### After (HTTP Transport)
```
Claude Code Extension
    ↓ HTTPS + Bearer Token
MCP Server (GCP)
```

## Full Command Reference

### n8n-MCP
```bash
# WSL/Linux
TOKEN=$(gcloud secrets versions access latest --secret=n8n-mcp-auth-token --project=abound-infr)
claude mcp add -t http n8n-mcp https://n8n-mcp.aboundtechology.com/mcp \
  -H "Authorization: Bearer $TOKEN"

# Windows PowerShell
$TOKEN = gcloud secrets versions access latest --secret=n8n-mcp-auth-token --project=abound-infr
claude mcp add -t http n8n-mcp https://n8n-mcp.aboundtechology.com/mcp `
  -H "Authorization: Bearer $TOKEN"
```

### ClickUp-MCP
```bash
# WSL/Linux
TOKEN=$(gcloud secrets versions access latest --secret=clickup-mcp-auth-token --project=abound-infr)
claude mcp add -t http clickup-mcp https://clickup-mcp.aboundtechology.com/mcp \
  -H "Authorization: Bearer $TOKEN"

# Windows PowerShell
$TOKEN = gcloud secrets versions access latest --secret=clickup-mcp-auth-token --project=abound-infr
claude mcp add -t http clickup-mcp https://clickup-mcp.aboundtechology.com/mcp `
  -H "Authorization: Bearer $TOKEN"
```

## Troubleshooting HTTP Transport

### Check Server Health
```bash
TOKEN=$(gcloud secrets versions access latest --secret=n8n-mcp-auth-token --project=abound-infr)
curl -H "Authorization: Bearer $TOKEN" https://n8n-mcp.aboundtechology.com/health
```

### Test MCP Endpoint
```bash
curl -X POST https://n8n-mcp.aboundtechology.com/mcp \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

### Check Claude Code Version
```bash
claude --version
```

HTTP transport requires Claude Code from June 2025 or later.

---

## Recommendation

**✅ Migrate to HTTP transport immediately**

The bridge script is unnecessary complexity. HTTP transport is:
- Officially supported by Anthropic
- Simpler to setup and maintain
- Better performance
- Standard across all Claude Code installations

---

**Last Updated:** October 9, 2025
**Claude Code Version:** June 2025+
