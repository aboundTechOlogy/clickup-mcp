# ClickUp MCP Server Deployment

**Status:** 🚧 In Progress
**Service:** ClickUp MCP Server
**Port:** 3002
**Subdomain:** clickup-mcp.aboundtechology.com
**VM:** abound-infra-vm (35.185.61.108)
**Date Started:** October 9, 2025

---

## 📋 Overview

Deploying ClickUp MCP server to GCP VM following proven patterns from n8n-mcp deployment. This server provides MCP tools for ClickUp task management integration.

**Package:** `@taazkareem/clickup-mcp-server`
**Transport:** HTTP/SSE (native)
**Location:** `/opt/ai-agent-platform/mcp-servers/clickup-mcp/`

---

## 🎯 Prerequisites

### Required Information
- [ ] ClickUp API Key (from https://app.clickup.com/settings/apps)
- [ ] ClickUp Team/Workspace ID (from URL: `https://app.clickup.com/<TEAM_ID>/...`)
- [ ] GCP Project ID: `abound-infr`
- [ ] VM Service Account email

### System Requirements
- [ ] VM has gcloud CLI configured
- [ ] Systemd available
- [ ] Port 3002 available
- [ ] Caddy proxy running

---

## 📦 Step 1: Pre-Deployment Checks

### 1.1 SSH to VM
```bash
gcloud compute ssh abound-infra-vm --zone=us-east1-c --project=abound-infr
```

### 1.2 Verify Directory Structure
```bash
ls -la /opt/ai-agent-platform/
ls -la /opt/ai-agent-platform/mcp-servers/
```

**Expected:** Should see `n8n-mcp/` directory

### 1.3 Check Port Availability
```bash
sudo lsof -i :3002
```

**Expected:** No output (port is free)

### 1.4 Verify Secrets Manager Access
```bash
gcloud secrets list --project=abound-infr
```

**Expected:** Should list existing secrets (including n8n-mcp secrets)

---

## 🔑 Step 2: Create Secrets in Google Secrets Manager

### 2.1 Get VM Service Account
```bash
VM_SERVICE_ACCOUNT=$(gcloud compute instances describe abound-infra-vm \
  --zone=us-east1-c \
  --format='get(serviceAccounts[0].email)' \
  --project=abound-infr)
echo "VM Service Account: $VM_SERVICE_ACCOUNT"
```

**Record service account email:** ___________________________________

### 2.2 Create Auth Token
```bash
echo -n "$(openssl rand -base64 32)" | \
  gcloud secrets create clickup-mcp-auth-token \
  --data-file=- \
  --project=abound-infr
```

**Grant Access:**
```bash
gcloud secrets add-iam-policy-binding clickup-mcp-auth-token \
  --member="serviceAccount:$VM_SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor" \
  --project=abound-infr
```

**Test Access:**
```bash
gcloud secrets versions access latest --secret=clickup-mcp-auth-token --project=abound-infr
```

### 2.3 Create ClickUp API Key Secret
```bash
# Get API key from https://app.clickup.com/settings/apps
read -sp "Enter ClickUp API Key: " CLICKUP_API_KEY
echo

echo -n "$CLICKUP_API_KEY" | \
  gcloud secrets create clickup-mcp-api-key \
  --data-file=- \
  --project=abound-infr
```

**Grant Access:**
```bash
gcloud secrets add-iam-policy-binding clickup-mcp-api-key \
  --member="serviceAccount:$VM_SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor" \
  --project=abound-infr
```

**Test Access:**
```bash
gcloud secrets versions access latest --secret=clickup-mcp-api-key --project=abound-infr
```

### 2.4 Record Team ID
```bash
# From ClickUp URL: https://app.clickup.com/XXXXXXX/...
read -p "Enter ClickUp Team ID: " CLICKUP_TEAM_ID
echo "Team ID: $CLICKUP_TEAM_ID"
```

**Record Team ID:** ___________________________________

---

## 📦 Step 3: Installation on VM

### 3.1 Create Directory
```bash
cd /opt/ai-agent-platform/mcp-servers/
sudo mkdir clickup-mcp
sudo chown -R root:root clickup-mcp
cd clickup-mcp
```

### 3.2 Install Package
```bash
# Install globally for easier access
sudo npm install -g @taazkareem/clickup-mcp-server@latest

# Verify installation
which clickup-mcp-server
npm list -g @taazkareem/clickup-mcp-server
```

**Installed version:** ___________________________________

### 3.3 Test Basic Functionality (Optional)
```bash
# Quick test to verify package works
export CLICKUP_API_KEY=$(gcloud secrets versions access latest --secret=clickup-mcp-api-key --project=abound-infr)
export CLICKUP_TEAM_ID=<YOUR_TEAM_ID>
export PORT=3002
export ENABLE_SSE=true

# Run briefly to test
timeout 10 npx -y @taazkareem/clickup-mcp-server@latest || echo "Package runs successfully"
```

---

## 🔧 Step 4: Create Load Secrets Script

### 4.1 Create `load-secrets.sh`
```bash
sudo tee /opt/ai-agent-platform/mcp-servers/clickup-mcp/load-secrets.sh > /dev/null << 'EOF'
#!/bin/bash
set -e

PROJECT_ID="abound-infr"
cd /opt/ai-agent-platform/mcp-servers/clickup-mcp

echo "Loading secrets from Google Secret Manager..."

# Fetch secrets
export AUTH_TOKEN=$(gcloud secrets versions access latest --secret="clickup-mcp-auth-token" --project="$PROJECT_ID")
export CLICKUP_API_KEY=$(gcloud secrets versions access latest --secret="clickup-mcp-api-key" --project="$PROJECT_ID")

# Configuration
export PORT=3002
export HOST=0.0.0.0
export NODE_ENV=production
export ENABLE_SSE=true
export CLICKUP_TEAM_ID="<YOUR_TEAM_ID>"  # Replace with actual team ID
export ENABLED_TOOLS="get_task,create_task,update_task,search_tasks,create_comment,get_list,get_folder,get_space"
export LOG_LEVEL=info

echo "Secrets loaded successfully"
echo "Starting ClickUp MCP server on port $PORT..."

# Start application
exec npx -y @taazkareem/clickup-mcp-server@latest
EOF
```

### 4.2 Update Team ID in Script
```bash
# Replace <YOUR_TEAM_ID> with actual team ID
sudo sed -i "s/<YOUR_TEAM_ID>/$CLICKUP_TEAM_ID/" /opt/ai-agent-platform/mcp-servers/clickup-mcp/load-secrets.sh
```

### 4.3 Make Script Executable
```bash
sudo chmod +x /opt/ai-agent-platform/mcp-servers/clickup-mcp/load-secrets.sh
```

### 4.4 Test Load Secrets Script
```bash
sudo /opt/ai-agent-platform/mcp-servers/clickup-mcp/load-secrets.sh &
SCRIPT_PID=$!
sleep 5
curl http://localhost:3002/health
sudo kill $SCRIPT_PID
```

**Expected:** Health check should return success

---

## ⚙️ Step 5: Create Systemd Service

### 5.1 Create Service File
```bash
sudo tee /etc/systemd/system/clickup-mcp.service > /dev/null << 'EOF'
[Unit]
Description=ClickUp MCP Server
After=network.target
Documentation=https://github.com/taazkareem/clickup-mcp-server

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/ai-agent-platform/mcp-servers/clickup-mcp

# Start via load-secrets.sh which sets environment and runs server
ExecStart=/opt/ai-agent-platform/mcp-servers/clickup-mcp/load-secrets.sh

Restart=always
RestartSec=10

# Security
NoNewPrivileges=true
PrivateTmp=true

# Resources
MemoryLimit=512M
CPUQuota=50%

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=clickup-mcp

[Install]
WantedBy=multi-user.target
EOF
```

### 5.2 Reload Systemd
```bash
sudo systemctl daemon-reload
```

### 5.3 Enable and Start Service
```bash
sudo systemctl enable clickup-mcp
sudo systemctl start clickup-mcp
```

### 5.4 Verify Service Status
```bash
sudo systemctl status clickup-mcp
```

**Expected:** Active (running)

### 5.5 Check Logs
```bash
sudo journalctl -u clickup-mcp -n 50
```

**Expected:** Should see "Secrets loaded successfully" and server startup messages

---

## 🌐 Step 6: Configure Caddy Reverse Proxy

### 6.1 Locate Caddy Configuration
```bash
ls -la /opt/ai-agent-platform/proxy/
cat /opt/ai-agent-platform/proxy/Caddyfile
```

### 6.2 Add ClickUp MCP Block
```bash
sudo tee -a /opt/ai-agent-platform/proxy/Caddyfile > /dev/null << 'EOF'

# ClickUp MCP Server
clickup-mcp.aboundtechology.com {
    encode zstd gzip
    reverse_proxy 127.0.0.1:3002 {
        header_up Authorization {http.request.header.Authorization}
        header_up Mcp-Session-Id {http.request.header.Mcp-Session-Id}
        header_down Mcp-Session-Id {http.response.header.Mcp-Session-Id}
        header_up Host {host}
        header_up X-Real-IP {remote_host}
    }
}
EOF
```

### 6.3 Restart Caddy
```bash
docker restart n8n-proxy-caddy-1
```

### 6.4 Check Caddy Logs
```bash
docker logs n8n-proxy-caddy-1 --tail 50
```

**Expected:** Should see certificate provisioning for clickup-mcp.aboundtechology.com

### 6.5 Wait for SSL Certificate
```bash
# Wait 30-60 seconds for Let's Encrypt cert
sleep 60
```

---

## ✅ Step 7: Verification & Testing

### 7.1 Local Health Check
```bash
curl http://localhost:3002/health
```

**Expected:** `{"status":"ok"}` or similar

### 7.2 Local MCP Endpoint Test
```bash
AUTH_TOKEN=$(gcloud secrets versions access latest --secret=clickup-mcp-auth-token --project=abound-infr)

curl -X POST http://localhost:3002/mcp \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq '.'
```

**Expected:** Should return list of available ClickUp tools

### 7.3 External Health Check
```bash
curl https://clickup-mcp.aboundtechology.com/health
```

**Expected:** `{"status":"ok"}` over HTTPS

### 7.4 External MCP Endpoint Test
```bash
curl -X POST https://clickup-mcp.aboundtechology.com/mcp \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq '.'
```

**Expected:** Should return same tools list over HTTPS

---

## 🖥️ Step 8: Client Configuration

### 8.1 Claude Desktop (OAuth)

**Note:** Check if ClickUp MCP supports OAuth auto-discovery. If not, skip to HTTP configuration.

### 8.2 Cursor WSL Configuration

**File:** `~/.cursor/mcp.json`

```json
{
  "mcpServers": {
    "clickup": {
      "transport": {
        "type": "http",
        "url": "https://clickup-mcp.aboundtechology.com/mcp",
        "headers": {
          "Authorization": "Bearer <YOUR_AUTH_TOKEN>"
        }
      }
    }
  }
}
```

### 8.3 Cursor Windows Configuration

**File:** `C:\Users\<username>\.cursor\mcp.json`

Same as WSL configuration above.

### 8.4 Claude Code Windows (Bridge Script)

**Create:** `windows-bridge/clickup-mcp-bridge.js`

```javascript
// Based on n8n-mcp-bridge.js pattern
// Converts stdio to HTTP with bearer token
// Tracks Mcp-Session-Id headers

const https = require('https');
const readline = require('readline');

const BASE_URL = 'https://clickup-mcp.aboundtechology.com/mcp';
const AUTH_TOKEN = process.env.CLICKUP_MCP_AUTH_TOKEN;

let sessionId = null;

// ... (implement full bridge logic based on n8n-mcp pattern)
```

---

## 🔍 Step 9: Troubleshooting

### 9.1 Service Won't Start
```bash
# Check service status
sudo systemctl status clickup-mcp

# Check logs
sudo journalctl -u clickup-mcp -n 100

# Common issues:
# - Secrets access denied → verify IAM binding
# - Port in use → check with lsof
# - Package not found → reinstall globally
```

### 9.2 Can't Access Secrets
```bash
# Test secret access
gcloud secrets versions access latest --secret=clickup-mcp-auth-token --project=abound-infr

# If fails, check IAM binding
gcloud secrets get-iam-policy clickup-mcp-auth-token --project=abound-infr
```

### 9.3 External Access Fails
```bash
# Check Caddy status
docker ps | grep caddy

# Check Caddy logs
docker logs n8n-proxy-caddy-1 --tail 100

# Test DNS resolution
nslookup clickup-mcp.aboundtechology.com
```

### 9.4 Session ID Issues
- Ensure bridge scripts track `Mcp-Session-Id` header
- Check server supports persistent sessions
- Review n8n-mcp bridge implementation for pattern

---

## 📊 Step 10: Monitoring

### 10.1 Service Status
```bash
sudo systemctl status clickup-mcp
```

### 10.2 Real-time Logs
```bash
sudo journalctl -u clickup-mcp -f
```

### 10.3 Resource Usage
```bash
sudo systemctl show clickup-mcp --property=MemoryCurrent,CPUUsageCurrent
```

### 10.4 Error Logs
```bash
sudo journalctl -u clickup-mcp -p err -n 50
```

---

## ✅ Deployment Checklist

- [ ] Pre-deployment checks completed
- [ ] Secrets created in Secret Manager
- [ ] VM service account granted access
- [ ] Package installed on VM
- [ ] `load-secrets.sh` created and tested
- [ ] Systemd service created and running
- [ ] Caddy reverse proxy configured
- [ ] SSL certificate provisioned
- [ ] Local health check passing
- [ ] Local MCP endpoint working
- [ ] External health check passing
- [ ] External MCP endpoint working
- [ ] Cursor WSL configured
- [ ] Cursor Windows configured
- [ ] Bridge script created (if needed)
- [ ] All clients tested
- [ ] Monitoring in place

---

## 📝 Deployment Notes

### Deployment Start Time
Date: ___________________________________
Time: ___________________________________

### Deployment End Time
Date: ___________________________________
Time: ___________________________________

### Issues Encountered
1. ___________________________________
2. ___________________________________
3. ___________________________________

### Solutions Applied
1. ___________________________________
2. ___________________________________
3. ___________________________________

### Auth Token (for reference - stored in Secret Manager)
Secret Name: `clickup-mcp-auth-token`
Retrieved via: `gcloud secrets versions access latest --secret=clickup-mcp-auth-token --project=abound-infr`

### ClickUp Team ID
Team ID: ___________________________________

### Service Health
```bash
# Check all MCP services
sudo systemctl status n8n-mcp clickup-mcp
```

---

## 🎯 Next Steps

After ClickUp deployment is complete:

1. Test all client integrations thoroughly
2. Document any additional issues in this file
3. Update DEPLOYMENT_PLAN_V2.md with lessons learned
4. Proceed to Notion MCP deployment (Port 3003)

---

**Deployment Status:** 🚧 In Progress
**Last Updated:** October 9, 2025
