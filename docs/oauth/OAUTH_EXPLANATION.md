# OAuth for Claude Desktop Custom Connectors - Explained

## What You Asked

> "Do I need to create a GitHub OAuth app for this server?"
> "How is this going to work for Claude Desktop Custom Connectors?"

## The Answer

**NO, you do not need GitHub OAuth.** Here's why and what we actually need:

## How Claude Desktop Custom Connectors Work

### What Claude Desktop Needs:

1. **OAuth 2.1 Authorization Server** (the MCP server itself acts as OAuth server)
2. **Dynamic Client Registration (DCR)** - RFC 7591
3. **Authorization Server Metadata** - RFC 8414
4. **PKCE** - Proof Key for Code Exchange (mandatory)
5. **Standard OAuth endpoints**:
   - `/.well-known/oauth-authorization-server` - Server metadata
   - `/oauth/register` - For DCR (Claude registers itself)
   - `/oauth/authorize` - User authorization
   - `/oauth/token` - Token exchange
   - `/oauth/revoke` - Token revocation

### What It Does NOT Need:

- ❌ GitHub OAuth App
- ❌ Credentials in config files
- ❌ Manual client registration

## The OAuth Flow

```
1. User adds connector in Claude Desktop
   URL: https://clickup-mcp.aboundtechology.com/mcp

2. Claude discovers OAuth endpoints
   GET /.well-known/oauth-authorization-server

3. Claude registers itself (DCR)
   POST /oauth/register
   {
     "client_name": "Claude",
     "redirect_uris": ["https://claude.ai/api/mcp/auth_callback"]
   }

4. Server returns client_id
   {
     "client_id": "auto-generated-uuid"
   }

5. Claude initiates OAuth flow
   GET /oauth/authorize?client_id=...&code_challenge=...

6. User sees consent page in browser
   "Authorize Claude to access ClickUp MCP?"
   [Authorize] [Deny]

7. User clicks Authorize

8. Server redirects back to Claude
   https://claude.ai/api/mcp/auth_callback?code=...

9. Claude exchanges code for token
   POST /oauth/token
   {
     "code": "...",
     "code_verifier": "..."
   }

10. Server returns access token
    {
      "access_token": "...",
      "token_type": "Bearer",
      "expires_in": 3600
    }

11. Claude uses token for all MCP requests
    Authorization: Bearer <access_token>
```

## Why n8n-mcp Works But ClickUp MCP Doesn't

### n8n-mcp Server

✅ Built with custom code we control
✅ Uses `@modelcontextprotocol/sdk` with `mcpAuthRouter`
✅ Has OAuth 2.1 + DCR built-in
✅ Works with Claude Desktop Custom Connectors immediately

### ClickUp MCP Package (`@taazkareem/clickup-mcp-server`)

❌ Third-party npm package
❌ Uses `@modelcontextprotocol/sdk` but doesn't expose OAuth
❌ Only supports bearer token authentication
❌ Cannot work with Claude Desktop Custom Connectors directly

## The Solution: OAuth Proxy

Since we can't modify the ClickUp MCP package, we wrap it with an OAuth proxy:

```
Claude Desktop
     ↓ (OAuth 2.1)
[OAuth Proxy] :3002
  ↓ (validates OAuth token)
  ↓ (adds ClickUp bearer token)
[ClickUp MCP] :3003
  ↓ (uses ClickUp API)
ClickUp API
```

### What the OAuth Proxy Does:

1. **Provides OAuth 2.1 endpoints** - DCR, authorize, token
2. **Issues its own OAuth tokens** - Validates them on requests
3. **Stores client registrations** - SQLite database
4. **Proxies to ClickUp MCP** - Adds bearer token authentication
5. **Manages sessions** - Forwards Mcp-Session-Id headers

## Deployment Architecture

### Current (Without OAuth - Doesn't Work with Claude Desktop):
```
https://clickup-mcp.aboundtechology.com
    ↓
[Caddy] :443
    ↓
[ClickUp MCP] :3002
```

### After OAuth Proxy (Works with Claude Desktop):
```
https://clickup-mcp.aboundtechology.com
    ↓
[Caddy] :443
    ↓
[OAuth Proxy] :3002 (new port for OAuth proxy)
    ↓
[ClickUp MCP] :3003 (moved to new port)
```

## No GitHub OAuth Confusion

You mentioned we used GitHub OAuth for n8n-mcp. Let me clarify:

- **We did NOT use GitHub OAuth** for the main OAuth flow
- n8n-mcp has its own built-in OAuth 2.1 server
- The `github-oauth-provider.ts` file exists but may have been for a different use case or experimentation
- Claude Desktop does NOT require GitHub OAuth - it needs the MCP server to BE an OAuth server

## Next Steps

1. **Deploy OAuth Proxy** - Add OAuth 2.1 wrapper to ClickUp MCP
2. **Move ClickUp MCP to port 3003** - Make room for OAuth proxy on 3002
3. **Update Caddy** - Proxy to OAuth proxy instead of ClickUp MCP directly
4. **Test with Claude Desktop** - Add connector via Settings > Connectors

## Summary

- **No GitHub OAuth app needed**
- **No credentials in Claude Desktop config**
- **MCP server acts as its own OAuth authorization server**
- **OAuth proxy adds missing OAuth 2.1 + DCR to ClickUp MCP**
- **User authorizes once in browser, tokens managed automatically**

## References

- [MCP OAuth 2.1 Specification](https://modelcontextprotocol.io/specification/2025-03-26/basic/authorization)
- [Claude Desktop Custom Connectors](https://support.claude.com/en/articles/11503834-building-custom-connectors-via-remote-mcp-servers)
- [Dynamic Client Registration RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)
- [Authorization Server Metadata RFC 8414](https://datatracker.ietf.org/doc/html/rfc8414)
