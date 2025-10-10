# GitHub OAuth Setup for ClickUp MCP - Complete Guide

Following the exact same pattern as your n8n-mcp deployment.

## Why GitHub OAuth?

- ✅ **Required for Claude Desktop** - Custom Connectors need OAuth 2.1
- ✅ **Better Security** - GitHub verifies user identity before issuing tokens
- ✅ **No credentials in config files** - OAuth flow happens in browser
- ✅ **Same pattern as n8n-mcp** - Proven approach you're already using

## Step 1: Create GitHub OAuth App

1. Go to https://github.com/settings/developers
2. Click **OAuth Apps** → **New OAuth App**
3. Fill in the details:
   ```
   Application name: ClickUp MCP Server
   Homepage URL: https://clickup-mcp.aboundtechology.com
   Application description: MCP server for ClickUp integration with Claude Desktop
   Authorization callback URL: https://clickup-mcp.aboundtechology.com/oauth/callback
   ```
4. Click **Register application**
5. On the app page, click **Generate a new client secret**
6. **Save both values immediately** (client secret only shown once)

## Step 2: Store Credentials in Google Secrets Manager

Run these commands from your local machine (replace the values):

```bash
# Store GitHub Client ID
echo -n "Iv1.YOUR_CLIENT_ID_HERE" | \
  gcloud secrets create clickup-mcp-github-client-id \
  --data-file=- \
  --replication-policy="automatic" \
  --project=abound-infr

# Store GitHub Client Secret
echo -n "YOUR_CLIENT_SECRET_HERE" | \
  gcloud secrets create clickup-mcp-github-client-secret \
  --data-file=- \
  --replication-policy="automatic" \
  --project=abound-infr

# Get VM service account
VM_SERVICE_ACCOUNT=$(gcloud compute instances describe abound-infra-vm \
  --zone=us-east1-c \
  --project=abound-infr \
  --format='get(serviceAccounts[0].email)')

echo "VM Service Account: $VM_SERVICE_ACCOUNT"

# Grant VM access to GitHub secrets
gcloud secrets add-iam-policy-binding clickup-mcp-github-client-id \
  --member="serviceAccount:$VM_SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor" \
  --project=abound-infr

gcloud secrets add-iam-policy-binding clickup-mcp-github-client-secret \
  --member="serviceAccount:$VM_SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor" \
  --project=abound-infr
```

## Step 3: Verify Access

Test that secrets are accessible:

```bash
gcloud secrets versions access latest --secret="clickup-mcp-github-client-id" --project="abound-infr"
gcloud secrets versions access latest --secret="clickup-mcp-github-client-secret" --project="abound-infr"
```

## OAuth Flow (How It Works)

1. **User adds connector in Claude Desktop**
   - URL: `https://clickup-mcp.aboundtechology.com/mcp`

2. **Claude discovers OAuth endpoints**
   - GET `/.well-known/oauth-authorization-server`

3. **Claude registers itself (Dynamic Client Registration)**
   - POST `/oauth/register`

4. **Claude initiates OAuth flow**
   - Redirects user to `/oauth/authorize`

5. **OAuth proxy redirects to GitHub**
   - User sees GitHub authorization page
   - "Authorize ClickUp MCP Server to access your account?"

6. **User authorizes on GitHub**
   - GitHub redirects back to `/oauth/callback`

7. **OAuth proxy verifies GitHub identity**
   - Exchanges GitHub code for access token
   - Verifies user's GitHub account

8. **OAuth proxy issues MCP token**
   - Redirects back to Claude with MCP authorization code

9. **Claude exchanges code for token**
   - POST `/oauth/token`

10. **Claude uses token for all MCP requests**
    - `Authorization: Bearer <token>`
    - Token validated against GitHub-authenticated session

## Security Benefits

### Compared to Bearer Tokens:
- ❌ Bearer token: Anyone with token has access
- ✅ GitHub OAuth: Must authenticate with GitHub account first

### Compared to Built-in OAuth:
- ❌ Built-in OAuth: Server just issues tokens, no identity verification
- ✅ GitHub OAuth: GitHub verifies user identity before token issuance

## Architecture

```
Claude Desktop
     ↓ (OAuth 2.1 + DCR)
[OAuth Proxy] :3002
  ↓ (validates GitHub OAuth token)
  ↓ (adds ClickUp bearer token)
[ClickUp MCP] :3003
  ↓ (uses ClickUp API)
ClickUp API
```

## Files Created

- `/opt/ai-agent-platform/mcp-servers/clickup-mcp/oauth-proxy/` - OAuth proxy
- `oauth.db` - SQLite database for OAuth sessions
- Service runs as `clickup-mcp-oauth-proxy.service`

## Next Steps

After creating the GitHub OAuth App and storing credentials:
1. Deploy OAuth proxy to GCP VM
2. Move ClickUp MCP from port 3002 → 3003
3. Start OAuth proxy on port 3002
4. Update Caddy to proxy to OAuth proxy
5. Test with Claude Desktop

## Troubleshooting

### "Invalid redirect_uri"
- Check GitHub OAuth App callback URL matches: `https://clickup-mcp.aboundtechology.com/oauth/callback`

### "Invalid client_id or client_secret"
- Verify secrets in Google Secrets Manager
- Check VM has permission to access secrets

### "GitHub OAuth error"
- Check OAuth proxy logs: `sudo journalctl -u clickup-mcp-oauth-proxy -n 50`
- Verify GitHub OAuth App is active

## Comparison with n8n-mcp

Both deployments use identical OAuth approach:

| Feature | n8n-mcp | ClickUp MCP |
|---------|---------|-------------|
| OAuth Provider | GitHub | GitHub |
| Port | 3000 | 3002 |
| Backend Port | n8n (5678) | ClickUp MCP (3003) |
| Secrets Manager | ✅ | ✅ |
| Dynamic Client Registration | ✅ | ✅ |
| Token Expiry | 1 hour | 1 hour |
| SQLite Storage | ✅ | ✅ |

Same security model, same proven approach! 🎉
