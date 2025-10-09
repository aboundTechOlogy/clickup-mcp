# ClickUp MCP Deployment Project

This project contains documentation and scripts for deploying the ClickUp MCP server to GCP VM alongside the existing n8n-mcp server.

**Repository:** `aboundTechOlogy/clickup-mcp`

This project serves as a template for future MCP server deployments.

## 📁 Project Structure

```
clickup-mcp/
├── README.md                     # This file
├── DEPLOYMENT_PLAN_V2.md        # Main deployment plan (lessons learned from n8n-mcp)
├── clickup/
│   ├── DEPLOYMENT.md            # ✅ Complete ClickUp deployment guide
│   └── DEPLOYMENT_NOTES.md      # ⚠️ Important config notes (--env syntax)
└── scripts/                      # ✅ Helper scripts
    ├── README.md                # Script documentation
    ├── setup-clickup-secrets.sh # Create secrets in Secret Manager
    ├── deploy-clickup.sh        # Deploy service on VM (updated syntax)
    ├── health-check-all.sh      # Check health of all services
    └── test-mcp-endpoint.sh     # Test MCP JSON-RPC endpoint
```

## 🎯 Overview

**Goal:** Deploy ClickUp MCP server to GCP VM (abound-infra-vm) alongside existing n8n-mcp server

**Current Status:**
- ✅ n8n-mcp - Deployed and operational (port 3000)
- 🚧 ClickUp MCP - Documentation and scripts ready (port 3002)
- 🔜 Future: Notion MCP, Google Workspace MCP, GitHub MCP (separate projects)

## 📚 Key Documents

### [DEPLOYMENT_PLAN_V2.md](./DEPLOYMENT_PLAN_V2.md)
**Main deployment guide** incorporating all lessons learned from n8n-mcp deployment:
- Proper directory structure (`/opt/ai-agent-platform/mcp-servers/`)
- Google Secrets Manager integration
- Systemd service configuration
- Multi-environment client setup
- Bridge scripts for Claude Code Windows
- Comprehensive testing procedures

## 🔑 Critical Lessons from n8n-mcp

1. **Directory Investigation First** - Always explore VM structure before deploying
2. **Google Secrets Manager** - Essential for credential management
3. **Secrets Loader Scripts** - Every service needs `load-secrets.sh`
4. **Systemd Configuration** - Specific patterns for security and resource limits
5. **Session-Based Auth** - Track `Mcp-Session-Id` headers
6. **Bridge Scripts** - Required for Claude Code Windows compatibility
7. **Multi-Environment Testing** - Test all 5 client environments
8. **Caddy Reverse Proxy** - Extend existing configuration
9. **Comprehensive Health Checks** - Local + external + MCP protocol
10. **Documentation Standards** - Document everything as you go

## 🚀 Quick Start

### 1. Create Secrets (run from local machine)
```bash
./scripts/setup-clickup-secrets.sh
```
You'll need:
- ClickUp API key (from https://app.clickup.com/settings/apps)

### 2. Deploy to VM (run on GCP VM)
```bash
# SSH to VM
gcloud compute ssh abound-infra-vm --zone=us-east1-c --project=abound-infr

# Clone/copy this project to VM
# Then run deployment script
./scripts/deploy-clickup.sh
```
You'll need:
- ClickUp Team ID (from URL: https://app.clickup.com/XXXXXXX/...)

### 3. Configure Caddy Reverse Proxy (manual on VM)
See [clickup/DEPLOYMENT.md](./clickup/DEPLOYMENT.md) Step 6

### 4. Verify Deployment
```bash
# Check health
./scripts/health-check-all.sh

# Test MCP endpoint
./scripts/test-mcp-endpoint.sh clickup-mcp

# Test external access
./scripts/test-mcp-endpoint.sh clickup-mcp --external
```

**Estimated Time:** 2-4 hours (first deployment)

## 📋 Deployment Checklist

- [ ] Pre-deployment checks (port availability, secrets access)
- [ ] Secrets created in Google Secret Manager
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
- [ ] Client configurations created
- [ ] All clients tested

See detailed checklist in [clickup/DEPLOYMENT.md](./clickup/DEPLOYMENT.md)

## 🔗 Reference Materials

### n8n-mcp Project (Read-Only Reference)
- `/home/dreww/n8n-mcp/GCP_DEPLOYMENT_GUIDE.md` - Deployment patterns
- `/home/dreww/n8n-mcp/SECURE_MULTI_IDE_SETUP.md` - Client configs
- `/home/dreww/n8n-mcp/windows-bridge/` - Bridge script examples

### External Documentation
- [MCP Protocol Spec](https://modelcontextprotocol.io)
- [ClickUp API Docs](https://clickup.com/api)
- [Notion API Docs](https://developers.notion.com)
- [Google Workspace APIs](https://developers.google.com/workspace)
- [GitHub API Docs](https://docs.github.com/en/rest)

## 🧪 Testing Strategy

Each service must pass:
1. **Local Health Check** - `curl http://localhost:<PORT>/health`
2. **Local MCP Endpoint** - JSON-RPC initialize and tools/list
3. **External Access** - `curl https://<service>-mcp.aboundtechology.com/health`
4. **Claude Desktop** - OAuth or bearer token connection
5. **Cursor WSL** - Direct HTTP connection
6. **Cursor Windows** - Direct HTTP connection
7. **Claude Code Windows** - Bridge script connection

## 🔐 Security Architecture

### Server-Side
- **Bearer tokens** for HTTP authentication
- **Session IDs** for persistent connections
- **Google Secrets Manager** for all credentials
- **Systemd hardening** (NoNewPrivileges, PrivateTmp, etc.)
- **Resource limits** (512MB RAM, 50% CPU)

### Client-Side
- **Claude Desktop** - OAuth 2.0 (auto-discovery)
- **Claude Code WSL** - stdio (local server)
- **Claude Code Windows** - Bridge script (stdio → HTTPS)
- **Cursor WSL/Windows** - Direct HTTP with bearer token

## 📊 Port Allocation

| Service | Port | Status | Subdomain |
|---------|------|--------|-----------|
| n8n-mcp | 3000 | ✅ Active | n8n-mcp.aboundtechology.com |
| ClickUp | 3002 | 🔜 Planned | clickup-mcp.aboundtechology.com |
| Notion | 3003 | 🔜 Planned | notion-mcp.aboundtechology.com |
| Google Workspace | 3004 | 🔜 Planned | google-workspace-mcp.aboundtechology.com |
| GitHub | 3005 | 🔜 Planned | github-mcp.aboundtechology.com (if self-hosted) |

**Note:** Port 3001 reserved, not using Docker Compose (individual systemd services)

## 🚨 Common Pitfalls to Avoid

1. ❌ Deploying to wrong directory
2. ❌ Missing Secrets Manager permissions
3. ❌ Not tracking session IDs
4. ❌ Forgetting to reload Caddy
5. ❌ Port conflicts
6. ❌ Missing client environment testing
7. ❌ Inadequate documentation
8. ❌ Skipping health checks

## ✅ Success Criteria

Deployment complete when:
- All services in `/opt/ai-agent-platform/mcp-servers/`
- All credentials in Google Secrets Manager
- All services have systemd units
- All services accessible via HTTPS
- All clients configured and tested
- All documentation complete

## 🎯 Next Steps

1. ✅ Review deployment plan and create documentation
2. 🔜 Get ClickUp API key from https://app.clickup.com/settings/apps
3. 🔜 Run `./scripts/setup-clickup-secrets.sh` (from local machine)
4. 🔜 SSH to VM and run `./scripts/deploy-clickup.sh`
5. 🔜 Configure Caddy reverse proxy
6. 🔜 Test all endpoints and client configurations
7. 🔜 Update this project as template for future deployments

## 🔄 After ClickUp Deployment

Once ClickUp MCP is deployed:
1. ✅ Project named `clickup-mcp`
2. Create new projects for other services based on this template:
   - `notion-mcp`
   - `google-workspace-mcp`
   - `github-mcp`
3. Update `DEPLOYMENT_PLAN_V2.md` with ClickUp-specific lessons learned
4. Use updated plan for next service deployment

---

**Project Created:** October 9, 2025
**Based on:** n8n-mcp production deployment experience
**Current Focus:** ClickUp MCP Server
**Status:** 🚧 Ready for deployment
