# GitHub OAuth Setup for ClickUp MCP

To enable Claude Desktop Custom Connectors, we need to create a GitHub OAuth App.

## Step 1: Create GitHub OAuth App

1. Go to https://github.com/settings/developers
2. Click **OAuth Apps** → **New OAuth App**
3. Fill in the details:
   - **Application name**: `ClickUp MCP Server`
   - **Homepage URL**: `https://clickup-mcp.aboundtechology.com`
   - **Application description**: `MCP server for ClickUp integration with Claude Desktop`
   - **Authorization callback URL**: `https://clickup-mcp.aboundtechology.com/oauth/callback`
4. Click **Register application**
5. On the app page, click **Generate a new client secret**
6. **Save both values**:
   - Client ID (visible on page)
   - Client secret (only shown once)

## Step 2: Store Credentials in Google Secrets Manager

Run these commands (replace `YOUR_CLIENT_ID` and `YOUR_CLIENT_SECRET`):

```bash
# Store GitHub Client ID
echo -n "YOUR_CLIENT_ID" | \
  gcloud secrets create clickup-mcp-github-client-id \
  --data-file=- \
  --replication-policy="automatic" \
  --project=abound-infr

# Store GitHub Client Secret
echo -n "YOUR_CLIENT_SECRET" | \
  gcloud secrets create clickup-mcp-github-client-secret \
  --data-file=- \
  --replication-policy="automatic" \
  --project=abound-infr

# Get VM service account
VM_SERVICE_ACCOUNT=$(gcloud compute instances describe abound-infra-vm \
  --zone=us-east1-c \
  --project=abound-infr \
  --format='get(serviceAccounts[0].email)')

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

```bash
# Test that VM can access the secrets (run on VM)
gcloud secrets versions access latest --secret="clickup-mcp-github-client-id" --project="abound-infr"
gcloud secrets versions access latest --secret="clickup-mcp-github-client-secret" --project="abound-infr"
```

## OAuth Flow

1. Claude Desktop → OAuth proxy authorize endpoint
2. OAuth proxy → GitHub OAuth authorize
3. User authorizes on GitHub
4. GitHub → OAuth proxy callback (`/oauth/callback`)
5. OAuth proxy exchanges GitHub code for access token
6. OAuth proxy → Claude Desktop with MCP auth code
7. Claude Desktop → OAuth proxy token endpoint
8. OAuth proxy returns MCP access token
9. Claude Desktop uses token to call `/mcp` endpoint

## Security Notes

- GitHub OAuth provides user authentication
- OAuth proxy validates GitHub identity
- OAuth proxy issues its own tokens for MCP access
- Tokens expire after 1 hour
- ClickUp API credentials never exposed to Claude Desktop
