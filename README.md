# GCP MCP Deployment Project

Production deployment of MCP servers (n8n-mcp and ClickUp MCP) on Google Cloud Platform.

**Status**: ✅ **FULLY OPERATIONAL**

## 🎯 Quick Links

- **[Final Deployment Status](docs/deployment/FINAL_STATUS.md)** - Complete deployment details and test results
- **[Client Setup Guide](docs/client-setup/CLIENT_SETUP.md)** - Connect Claude Code to the servers
- **[OAuth Setup](docs/oauth/GITHUB_OAUTH_COMPLETE_SETUP.md)** - GitHub OAuth configuration

## 📡 Live Endpoints

| Service | Endpoint | Status |
|---------|----------|--------|
| n8n-MCP | `http://35.185.61.108:5678` | ✅ Running |
| ClickUp MCP | `http://35.185.61.108:3456` | ✅ Running |
| OAuth Proxy | `http://35.185.61.108:3457` | ✅ Running |

## 📁 Project Structure

```
gcp-mcp-deployment/
├── README.md                           # This file
├── DEPLOYMENT_PLAN_V2.md              # Original deployment planning
│
├── docs/                               # 📚 Documentation
│   ├── deployment/                     # Deployment guides and status
│   │   ├── FINAL_STATUS.md            # ✅ Current deployment status
│   │   ├── CLICKUP_DEPLOYMENT.md      # ClickUp deployment guide
│   │   └── CLICKUP_NOTES.md           # Important ClickUp config notes
│   ├── client-setup/                   # Client configuration
│   │   ├── CLIENT_SETUP.md            # Claude Code setup instructions
│   │   └── MIGRATION_GUIDE.md         # Bridge → HTTP migration
│   └── oauth/                          # OAuth documentation
│       ├── GITHUB_OAUTH_COMPLETE_SETUP.md
│       ├── GITHUB_OAUTH_SETUP.md
│       └── OAUTH_EXPLANATION.md
│
├── scripts/                            # 🔧 Deployment & maintenance scripts
│   ├── README.md                       # Script documentation
│   ├── setup-clickup-secrets.sh       # Initialize GCP secrets
│   ├── deploy-clickup.sh              # Deploy ClickUp MCP
│   ├── deploy-oauth-proxy.sh          # Deploy OAuth proxy
│   ├── health-check-all.sh            # Check all services
│   └── test-mcp-endpoint.sh           # Test MCP endpoints
│
├── oauth-proxy/                        # 🔐 OAuth proxy source code
│   ├── src/                            # TypeScript source
│   ├── dist/                           # Compiled JavaScript
│   ├── package.json
│   └── README.md
│
└── windows-bridge/                     # 🪟 Windows/WSL bridge
    ├── clickup-mcp-bridge.js          # Stdio → HTTPS bridge script
    └── README.md
```

## 🚀 Quick Start

### For Users (Connecting Claude Code)

1. Follow the **[Client Setup Guide](docs/client-setup/CLIENT_SETUP.md)**
2. Add the MCP server configuration to your Claude Code settings
3. Restart Claude Code
4. Start using n8n and ClickUp tools!

### For Administrators (Deployment)

1. Review **[DEPLOYMENT_PLAN_V2.md](DEPLOYMENT_PLAN_V2.md)** for architecture
2. Use scripts in `scripts/` for deployment and maintenance
3. Check **[Final Status](docs/deployment/FINAL_STATUS.md)** for current state

## 🔐 Security

- All credentials stored in **GCP Secret Manager**
- Services use systemd with resource limits
- OAuth tokens managed by dedicated proxy service
- No hardcoded credentials in any configuration files

## 🛠️ Services Overview

### n8n-MCP Server
- **535 nodes** including 269 AI tools
- **2,598 workflow templates** available
- Full workflow creation, validation, and execution
- Template management and node documentation

### ClickUp MCP Server
- **36 tools** for complete ClickUp integration
- Tasks, lists, folders, and workspace management
- Bulk operations for efficiency
- Time tracking and tag management
- File attachments and comments
- OAuth-based authentication

### OAuth Proxy
- GitHub OAuth integration for ClickUp
- Automatic token refresh
- Multi-user support with SQLite storage
- Secure credential management

## 📊 Testing

All tools have been comprehensively tested and verified:
- ✅ n8n-MCP: All core operations tested
- ✅ ClickUp MCP: All 36 tools tested successfully
- ✅ OAuth Proxy: Token flow and refresh verified

See [Final Status](docs/deployment/FINAL_STATUS.md) for detailed test results.

## 📝 Maintenance

### Health Checks
```bash
./scripts/health-check-all.sh
```

### View Service Logs
```bash
# On the VM
sudo journalctl -u n8n-mcp -f
sudo journalctl -u clickup-mcp -f
sudo journalctl -u clickup-mcp-oauth-proxy -f
```

### Restart Services
```bash
# On the VM
sudo systemctl restart n8n-mcp
sudo systemctl restart clickup-mcp
sudo systemctl restart clickup-mcp-oauth-proxy
```

## 🤝 Contributing

This project serves as a template for deploying MCP servers to GCP. When adding new MCP servers:

1. Follow the patterns in `scripts/` for deployment
2. Use GCP Secret Manager for credentials
3. Create systemd services with resource limits
4. Document thoroughly in `docs/`

## 📖 Additional Resources

- [MCP Protocol Specification](https://spec.modelcontextprotocol.io/)
- [Claude Code Documentation](https://docs.claude.com/claude-code)
- [n8n-MCP GitHub](https://github.com/aboundTechOlogy/n8n-mcp)
- [ClickUp MCP GitHub](https://github.com/taazkareem/clickup-mcp-server)

## 📅 Last Updated
October 9, 2025

---

**Infrastructure**: GCP VM `abound-infra-vm` (us-east1-c)
**Maintainer**: Andrew Whalen <andrew@aboundtechology.com>
