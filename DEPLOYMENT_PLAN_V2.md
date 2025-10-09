# GCP Multi-MCP Server Deployment Plan v2.0

**Project:** Multi-MCP Server Deployment on GCP VM
**VM:** abound-infra-vm (35.185.61.108)
**Updated:** October 2025
**Based on:** Production lessons from n8n-mcp deployment

---

## 🎯 Overview

Deploy 4 additional HTTP-enabled MCP servers alongside the existing n8n-mcp server on GCP VM, following proven deployment patterns.

**Servers to Deploy:**
1. ✅ **n8n-mcp** - Already deployed at port 3000
2. 🔜 **ClickUp MCP** - Port 3002
3. 🔜 **Notion MCP** - Port 3003
4. 🔜 **Google Workspace MCP** - Port 3004
5. 🔜 **GitHub MCP** - Port 3005 (or use remote hosted)

---

## 📁 Directory Structure (Lesson #1: Investigate First!)

```
/opt/ai-agent-platform/
├── n8n/                           # Existing n8n instance (Docker)
├── mcp-servers/                   # ✅ Correct location for all MCP servers
│   ├── n8n-mcp/                  # ✅ Already deployed
│   │   ├── dist/
│   │   ├── data/
│   │   ├── load-secrets.sh
│   │   └── ...
│   ├── clickup-mcp/              # 🔜 To deploy
│   ├── notion-mcp/               # 🔜 To deploy
│   ├── google-workspace-mcp/     # 🔜 To deploy
│   └── github-mcp/               # 🔜 To deploy (optional)
├── config/
├── docker-compose.yml             # n8n, postgres, Caddy proxy
└── proxy/                         # Caddy configuration
```

**Critical Lesson:** Always explore VM structure BEFORE choosing installation paths. We initially deployed n8n-mcp to `/opt/n8n-mcp` and had to relocate it.

---

## 🔑 Key Lessons from n8n-mcp Deployment

### Lesson #1: Directory Investigation
**What Happened:** Deployed to `/opt/n8n-mcp` without checking existing platform structure
**Impact:** Had to move entire server to `/opt/ai-agent-platform/mcp-servers/n8n-mcp`
**Fix:** Always run `ls -la /opt/`, `ls -la /home/`, etc. BEFORE starting

### Lesson #2: Google Secrets Manager is Essential
**Why:** No credentials in files, GCP IAM integration, easy rotation
**Pattern:**
```bash
# Create secret
echo -n "$(openssl rand -base64 32)" | \
  gcloud secrets create <service>-<secret-name> \
  --data-file=- \
  --project=abound-infr

# Grant VM access
VM_SERVICE_ACCOUNT=$(gcloud compute instances describe abound-infra-vm \
  --zone=us-east1-c \
  --format='get(serviceAccounts[0].email)')

gcloud secrets add-iam-policy-binding <service>-<secret-name> \
  --member="serviceAccount:$VM_SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor"
```

### Lesson #3: Secrets Loader Script Pattern
Every service needs `load-secrets.sh`:

```bash
#!/bin/bash
set -e

PROJECT_ID="abound-infr"
cd /opt/ai-agent-platform/mcp-servers/<service-name>

echo "Loading secrets from Google Secret Manager..."

# Fetch secrets
export AUTH_TOKEN=$(gcloud secrets versions access latest --secret="<service>-auth-token" --project="$PROJECT_ID")
export API_KEY=$(gcloud secrets versions access latest --secret="<service>-api-key" --project="$PROJECT_ID")

# Configuration
export PORT=<port>
export HOST=0.0.0.0
export NODE_ENV=production

echo "Secrets loaded successfully"

# Start application
exec <start-command>
```

### Lesson #4: Systemd Service Configuration
**Key requirements:**
- `User=root` (for gcloud access, or use service account with IAM)
- `WorkingDirectory=/opt/ai-agent-platform/mcp-servers/<service>`
- `ReadWritePaths` for data directories
- Resource limits (MemoryLimit, CPUQuota)
- Security hardening (NoNewPrivileges, PrivateTmp)

**Template:**
```ini
[Unit]
Description=<Service> MCP Server
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/ai-agent-platform/mcp-servers/<service>

ExecStart=/opt/ai-agent-platform/mcp-servers/<service>/load-secrets.sh

Restart=always
RestartSec=10

# Security
NoNewPrivileges=true
PrivateTmp=true
ReadWritePaths=/opt/ai-agent-platform/mcp-servers/<service>/data

# Resources
MemoryLimit=512M
CPUQuota=50%

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=<service>-mcp

[Install]
WantedBy=multi-user.target
```

### Lesson #5: Session-Based Authentication
**Discovery:** MCP HTTP server uses session IDs for persistent connections
**Implementation:** Must capture `Mcp-Session-Id` header from responses and include in subsequent requests
**Impact:** Critical for multi-request flows and bridge scripts

### Lesson #6: Claude Code Windows Bridge Script
**Challenge:** Claude Code CLI only supports stdio/SSE, not HTTP with bearer tokens
**Solution:** Bridge script that:
- Listens on stdin for JSON-RPC
- Forwards to HTTPS with bearer token
- Parses SSE responses
- Tracks session IDs

**Key Code:**
```javascript
let sessionId = null;

// In request
if (sessionId) {
  options.headers['Mcp-Session-Id'] = sessionId;
}

// In response
const newSessionId = res.headers['mcp-session-id'];
if (newSessionId) sessionId = newSessionId;

// SSE parsing
if (data.startsWith('event:')) {
  const lines = data.split('\n');
  const dataLine = lines.find(line => line.startsWith('data:'));
  const jsonData = dataLine.substring(5).trim();
  resolve(JSON.parse(jsonData));
}
```

### Lesson #7: Multi-Environment Support
Successfully configured 5 environments:
- ✅ Claude Desktop - OAuth to GCP server
- ✅ Claude Code WSL - Local stdio server
- ✅ Claude Code Windows - Bridge to GCP server
- ✅ Cursor WSL - Direct HTTP to GCP
- ✅ Cursor Windows - Direct HTTP to GCP

**Key:** Each has different capabilities and config patterns

### Lesson #8: Caddy Reverse Proxy
Existing Caddy proxy already running - extend it:

```caddyfile
<service>-mcp.aboundtechology.com {
    encode zstd gzip
    reverse_proxy 127.0.0.1:<PORT> {
        header_up Authorization {http.request.header.Authorization}
        header_up Mcp-Session-Id {http.request.header.Mcp-Session-Id}
        header_down Mcp-Session-Id {http.response.header.Mcp-Session-Id}
        header_up Host {host}
        header_up X-Real-IP {remote_host}
    }
}
```

### Lesson #9: Comprehensive Testing
Test matrix for each service:
1. Local health check: `curl http://localhost:<PORT>/health`
2. Local MCP endpoint: `curl -X POST http://localhost:<PORT>/mcp`
3. External health check: `curl https://<service>-mcp.aboundtechology.com/health`
4. Claude Desktop connection
5. Cursor WSL connection
6. Cursor Windows connection
7. Claude Code Windows bridge connection

### Lesson #10: Documentation Standards
For each service, document:
- Installation steps
- Secret creation
- Service configuration
- Client setup (all 5 environments)
- Troubleshooting (common issues we encountered)

---

## 📋 Deployment Checklist Template

Use this for each new service:

### Pre-Deployment
- [ ] Review VM directory structure
- [ ] Check port availability (`sudo lsof -i :<PORT>`)
- [ ] Plan subdomain name
- [ ] Review service dependencies

### Installation
- [ ] Create `/opt/ai-agent-platform/mcp-servers/<service>/`
- [ ] Install dependencies (npm/pip/etc)
- [ ] Test service locally before systemd
- [ ] Build if necessary

### Secrets Management
- [ ] Create auth token in Secrets Manager
- [ ] Create API keys in Secrets Manager
- [ ] Grant VM service account access
- [ ] Create `load-secrets.sh` script
- [ ] Test secret access: `gcloud secrets versions access latest --secret=<name>`

### Service Configuration
- [ ] Create `/etc/systemd/system/<service>-mcp.service`
- [ ] Set resource limits (512MB RAM, 50% CPU)
- [ ] Configure security hardening
- [ ] `sudo systemctl daemon-reload`
- [ ] `sudo systemctl enable <service>-mcp`
- [ ] `sudo systemctl start <service>-mcp`
- [ ] Verify: `sudo systemctl status <service>-mcp`

### Reverse Proxy
- [ ] Add Caddy block for `<service>-mcp.aboundtechology.com`
- [ ] Restart Caddy: `docker restart n8n-proxy-caddy-1`
- [ ] Wait for SSL cert (Let's Encrypt auto)
- [ ] Test external: `curl https://<service>-mcp.aboundtechology.com/health`

### Multi-Environment Setup
- [ ] Add to Claude Desktop (if OAuth supported)
- [ ] Add to Cursor WSL config (`~/.cursor/mcp.json`)
- [ ] Add to Cursor Windows config (`C:\Users\<user>\.cursor\mcp.json`)
- [ ] Create bridge script for Claude Code Windows (if needed)
- [ ] Test all 5 environments

### Documentation
- [ ] Create `<service>-DEPLOYMENT.md` in this project
- [ ] Document installation steps
- [ ] Document secrets setup
- [ ] Document client configuration
- [ ] Add troubleshooting section

### Verification
- [ ] Service running: `sudo systemctl status <service>-mcp`
- [ ] Health check works
- [ ] MCP endpoint works
- [ ] External access works
- [ ] All clients connected
- [ ] Logs clean: `sudo journalctl -u <service>-mcp -n 50`

---

## 🚀 Recommended Deployment Order

### Service 1: ClickUp MCP (Highest Priority)
**Port:** 3002
**Why First:** Native HTTP support, well-documented, critical for task management
**Dependencies:** ClickUp API key, Workspace ID
**Estimated Time:** 1 day

### Service 2: Notion MCP (High Priority)
**Port:** 3003
**Why Second:** Native HTTP support, simpler auth than Google Workspace
**Dependencies:** Notion integration token
**Estimated Time:** 1 day

### Service 3: Google Workspace MCP (Medium Priority)
**Port:** 3004
**Why Third:** More complex OAuth setup, multiple API scopes
**Dependencies:** GCP project, OAuth client, API enablement
**Estimated Time:** 2 days

### Service 4: GitHub MCP (Low Priority)
**Port:** 3005 or remote
**Why Last:** Can use GitHub's remote hosted server (zero maintenance)
**Dependencies:** GitHub PAT or OAuth
**Estimated Time:** 0.5 day (remote) or 1 day (self-hosted)

---

## 🔧 Service-Specific Configurations

### ClickUp MCP

**Package:** `@taazkareem/clickup-mcp-server`
**Transport:** HTTP/SSE (native)
**API Key:** Get from https://app.clickup.com/settings/apps

**Installation:**
```bash
cd /opt/ai-agent-platform/mcp-servers/
sudo mkdir clickup-mcp && cd clickup-mcp
sudo npm init -y
sudo npm install -g @taazkareem/clickup-mcp-server@latest
```

**Secrets to Create:**
- `clickup-mcp-auth-token` (generate with `openssl rand -base64 32`)
- `clickup-mcp-api-key` (from ClickUp settings)

**Environment Variables:**
```bash
export ENABLE_SSE=true
export PORT=3002
export CLICKUP_API_KEY=<from-secrets>
export CLICKUP_TEAM_ID=<from-url>
export ENABLED_TOOLS=get_task,create_task,update_task,search_tasks,create_comment
export LOG_LEVEL=info
```

**Start Command:**
```bash
exec npx -y @taazkareem/clickup-mcp-server@latest
```

**Subdomain:** `clickup-mcp.aboundtechology.com`

---

### Notion MCP

**Package:** `@notionhq/notion-mcp-server` (official)
**Transport:** HTTP (native)
**Token:** Create integration at https://www.notion.so/profile/integrations

**Installation:**
```bash
cd /opt/ai-agent-platform/mcp-servers/
sudo mkdir notion-mcp && cd notion-mcp
sudo npm init -y
sudo npm install -g @notionhq/notion-mcp-server
```

**Secrets to Create:**
- `notion-mcp-integration-token` (format: `secret_...`)
- `notion-mcp-auth-token` (generate with `openssl rand -base64 32`)

**Environment Variables:**
```bash
export NOTION_TOKEN=<from-secrets>
export AUTH_TOKEN=<from-secrets>
export PORT=3003
```

**Start Command:**
```bash
exec npx -y @notionhq/notion-mcp-server --transport http --port 3003 --auth-token "$AUTH_TOKEN"
```

**Important:** Share target Notion pages with integration (page settings → Connections)

**Subdomain:** `notion-mcp.aboundtechology.com`

---

### Google Workspace MCP

**Package:** `workspace-mcp` (Python/uvx)
**Transport:** Streamable HTTP
**OAuth:** Desktop application credentials

**Installation:**
```bash
cd /opt/ai-agent-platform/mcp-servers/
sudo mkdir google-workspace-mcp && cd google-workspace-mcp
sudo apt install python3-pip python3-venv -y
pip3 install pipx
pipx install workspace-mcp
```

**Secrets to Create:**
- `google-workspace-mcp-client-id`
- `google-workspace-mcp-client-secret`

**OAuth Setup (One-Time):**
1. Create GCP project
2. Enable APIs: Gmail, Calendar, Drive, Docs, Sheets
3. Create OAuth Desktop Client
4. Download credentials JSON
5. Run initial OAuth flow from VM

**Environment Variables:**
```bash
export GOOGLE_OAUTH_CLIENT_ID=<from-secrets>
export GOOGLE_OAUTH_CLIENT_SECRET=<from-secrets>
export WORKSPACE_MCP_BASE_URI=https://google-workspace-mcp.aboundtechology.com
export WORKSPACE_MCP_PORT=3004
export USER_GOOGLE_EMAIL=your@email.com
```

**Start Command:**
```bash
exec uvx workspace-mcp --transport streamable-http --tool-tier core
```

**Subdomain:** `google-workspace-mcp.aboundtechology.com`

---

### GitHub MCP

**Recommendation:** Use remote hosted server (easiest)
**URL:** `https://api.githubcopilot.com/mcp/`
**Auth:** OAuth 2.1 or Personal Access Token

**If Self-Hosting:**
```bash
cd /opt/ai-agent-platform/mcp-servers/
sudo mkdir github-mcp && cd github-mcp
sudo npm install -g @modelcontextprotocol/server-github
```

**For Remote (Recommended):**
- No installation on VM
- Configure in clients only
- Use GitHub OAuth or PAT

**Subdomain (if self-hosting):** `github-mcp.aboundtechology.com`

---

## 🧪 Testing Scripts

### Health Check All Services
```bash
#!/bin/bash
# health-check-all.sh

services=("n8n-mcp:3000" "clickup-mcp:3002" "notion-mcp:3003" "google-workspace-mcp:3004")

for service in "${services[@]}"; do
  IFS=':' read -r name port <<< "$service"
  echo -n "Testing $name (port $port)... "

  if curl -sf http://localhost:$port/health > /dev/null; then
    echo "✓ OK"
  else
    echo "✗ FAIL"
  fi
done
```

### Test MCP Endpoint
```bash
#!/bin/bash
# test-mcp-endpoint.sh

SERVICE=$1
PORT=$2
TOKEN=$3

curl -X POST http://localhost:$PORT/mcp \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq '.'
```

---

## 🔐 Authentication Summary

### Server-Side
- **Bearer tokens** in Authorization header
- **Session IDs** in Mcp-Session-Id header
- **Google Secrets Manager** for all credentials

### Client-Side

| Environment | Method | Configuration |
|-------------|--------|---------------|
| Claude Desktop | OAuth 2.0 | Auto-discovery |
| Claude Code WSL | stdio | Local server |
| Claude Code Windows | Bridge | stdio → HTTPS + sessions |
| Cursor WSL | HTTP Bearer | `~/.cursor/mcp.json` |
| Cursor Windows | HTTP Bearer | `C:\Users\<user>\.cursor\mcp.json` |

---

## 📊 Monitoring

### Service Status
```bash
sudo systemctl status n8n-mcp clickup-mcp notion-mcp google-workspace-mcp
```

### Logs
```bash
# Real-time
sudo journalctl -u <service>-mcp -f

# Last 50 lines
sudo journalctl -u <service>-mcp -n 50

# Errors only
sudo journalctl -u <service>-mcp -p err
```

### Resource Usage
```bash
sudo systemctl show <service>-mcp --property=MemoryCurrent,CPUUsageCurrent
```

---

## 🚨 Common Pitfalls (From Experience)

### Pitfall 1: Wrong Directory
**Symptom:** Service works but not in platform structure
**Fix:** Always use `/opt/ai-agent-platform/mcp-servers/<service>`

### Pitfall 2: Secrets Access Denied
**Symptom:** Service fails to start, permission errors
**Fix:** Grant VM service account `secretmanager.secretAccessor`
**Test:** `gcloud secrets versions access latest --secret=<name>`

### Pitfall 3: Session ID Missing
**Symptom:** First request works, second fails
**Fix:** Track `Mcp-Session-Id` header in responses
**Impact:** Required for bridge scripts

### Pitfall 4: Caddy Not Reloaded
**Symptom:** 502 Bad Gateway after config change
**Fix:** `docker restart n8n-proxy-caddy-1`

### Pitfall 5: Port Conflict
**Symptom:** Service won't start, "address in use"
**Fix:** Check with `sudo lsof -i :<PORT>` before deploying

---

## 📅 Estimated Timeline

| Phase | Duration | Tasks |
|-------|----------|-------|
| Planning | 0.5 day | Review this plan, prepare credentials |
| ClickUp Deployment | 1 day | Install, configure, test all clients |
| Notion Deployment | 1 day | Install, configure, test all clients |
| Google Workspace | 2 days | OAuth setup, install, configure, test |
| GitHub | 0.5 day | Configure remote or self-host |
| Integration Testing | 1 day | All services, all clients |
| Documentation | 1 day | Deployment guides, troubleshooting |
| **Total** | **7 days** | Full production deployment |

**Accelerated:** 4 days (skip detailed docs, basic testing)
**Recommended:** 7 days (comprehensive, production-ready)

---

## 📚 Reference Documents

From n8n-mcp project (read-only reference):
- `GCP_DEPLOYMENT_GUIDE.md` - Complete deployment pattern
- `SECURE_MULTI_IDE_SETUP.md` - Client configuration patterns
- `windows-bridge/n8n-mcp-bridge.js` - Bridge script template
- `CLAUDE.md` - Development standards

---

## ✅ Success Criteria

Deployment is complete when:
- [ ] All 5 services running in `/opt/ai-agent-platform/mcp-servers/`
- [ ] All credentials in Google Secrets Manager
- [ ] All services have systemd units (enabled, active)
- [ ] All services accessible via HTTPS subdomains
- [ ] All services configured in Claude Desktop
- [ ] All services configured in Cursor WSL & Windows
- [ ] Bridge scripts working for Claude Code Windows
- [ ] Health check script passing
- [ ] Documentation complete
- [ ] Team trained

---

## 🎯 Next Steps

1. Review this plan
2. Gather API keys and credentials
3. Start with ClickUp (highest priority)
4. Follow deployment checklist for each service
5. Test thoroughly before moving to next service
6. Document lessons learned along the way

---

**Version:** 2.0
**Created:** October 2025
**Based on:** n8n-mcp production deployment (8 weeks of learnings)
**Confidence:** High (95%) - patterns proven in production
