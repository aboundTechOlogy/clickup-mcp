# ClickUp MCP Server Deployment

Production deployment of ClickUp MCP server on GCP with OAuth proxy support.

**Status:** ✅ **FULLY OPERATIONAL**
**Deployment Date:** October 9, 2025

## 📡 Live Endpoints

| Service | Endpoint | Status |
|---------|----------|--------|
| ClickUp MCP | `http://35.185.61.108:3456` | ✅ Running |
| OAuth Proxy | `http://35.185.61.108:3457` | ✅ Running |

## 🎯 Overview

This repository contains the deployment configuration, OAuth proxy implementation, and client setup guides for the ClickUp MCP server running on GCP VM `abound-infra-vm`.

### Key Features
- **88 tools** for complete ClickUp integration (52 new tools added)
- Tasks, lists, folders, spaces, and workspace management
- Bulk operations for efficiency
- Time tracking and tag management
- File attachments and comments
- Custom fields, checklists, goals, dependencies
- Views, webhooks, guests, and user groups
- OAuth-based authentication via GitHub

## 📁 Project Structure

```
clickup-mcp/
├── README.md                           # This file
├── DEPLOYMENT_GUIDE.md                 # Reference to master deployment guide
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

### For Users (Connecting to ClickUp MCP)

1. Follow the **[Client Setup Guide](docs/client-setup/CLIENT_SETUP.md)**
2. Add the MCP server configuration to your IDE settings
3. Restart your IDE
4. Start using ClickUp tools!

**Example Configuration (Cursor/Claude Code):**
```json
{
  "mcpServers": {
    "clickup-mcp": {
      "transport": {
        "type": "http",
        "url": "http://35.185.61.108:3456"
      }
    }
  }
}
```

### For Administrators (Deployment)

1. Review **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** for deployment reference
2. Use scripts in `scripts/` for deployment and maintenance
3. Check **[Final Status](docs/deployment/FINAL_STATUS.md)** for current state

**Master Deployment Guide:** See `/home/dreww/mcp-deployment-guides/MCP_DEPLOYMENT_MASTER_GUIDE.md`

## 🔐 Security

- All credentials stored in **GCP Secret Manager**
- OAuth tokens managed by dedicated proxy service
- Services use systemd with resource limits
- No hardcoded credentials in any configuration files

**Secrets Used:**
- `clickup-mcp-api-key` - ClickUp API key
- `clickup-mcp-auth-token` - MCP server authentication
- `clickup-mcp-github-client-id` - GitHub OAuth client ID
- `clickup-mcp-github-client-secret` - GitHub OAuth client secret

## 🛠️ ClickUp MCP Server

**Version:** Enhanced (forked from `@taazkareem/clickup-mcp-server`)
**Port:** 3456
**Location:** `/opt/ai-agent-platform/mcp-servers/clickup-mcp-enhanced/`

### Available Tools (88 Total - Enhanced)

#### Workspace & Members (4)
- `get_workspace_hierarchy`, `get_workspace_members`, `find_member_by_name`, `resolve_assignees`

#### Lists (5)
- `create_list`, `create_list_in_folder`, `get_list`, `update_list`, `delete_list`

#### Folders (4)
- `create_folder`, `get_folder`, `update_folder`, `delete_folder`

#### Tasks (7)
- `create_task`, `get_task`, `update_task`, `move_task`, `duplicate_task`, `delete_task`, `get_workspace_tasks`

#### Bulk Tasks (4)
- `create_bulk_tasks`, `update_bulk_tasks`, `move_bulk_tasks`, `delete_bulk_tasks`

#### Comments & Files (3)
- `create_task_comment`, `get_task_comments`, `attach_task_file`

#### Time Tracking (6)
- `get_task_time_entries`, `start_time_tracking`, `stop_time_tracking`, `add_time_entry`, `delete_time_entry`, `get_current_time_entry`

#### Tags (3)
- `get_space_tags`, `add_tag_to_task`, `remove_tag_from_task`

#### **NEW** - Spaces (5)
- `create_space`, `get_spaces`, `get_space`, `update_space`, `delete_space`

#### **NEW** - Custom Fields (3)
- `get_accessible_custom_fields`, `set_custom_field_value`, `remove_custom_field_value`

#### **NEW** - Checklists (6)
- `create_checklist`, `update_checklist`, `delete_checklist`, `create_checklist_item`, `update_checklist_item`, `delete_checklist_item`

#### **NEW** - Goals (7)
- `create_goal`, `get_goal`, `update_goal`, `delete_goal`, `get_goals`, `create_key_result`, `update_key_result`, `delete_key_result`

#### **NEW** - Dependencies (4)
- `add_dependency`, `delete_dependency`, `add_task_link`, `delete_task_link`

#### **NEW** - Members & Guests (8)
- `get_task_members`, `get_list_members`, `invite_guest_to_workspace`, `edit_guest_on_workspace`, `remove_guest_from_workspace`, `get_guest`, `invite_guest_to_task`, `remove_guest_from_task`

#### **NEW** - Views (6)
- `create_view`, `get_view`, `update_view`, `delete_view`, `get_views`, `get_view_tasks`

#### **NEW** - Webhooks (4)
- `create_webhook`, `update_webhook`, `delete_webhook`, `get_webhooks`

#### **NEW** - Miscellaneous (10)
- `get_shared_hierarchy`, `create_folder_from_template`, `create_list_from_template`, `get_authorized_user`, `create_user_group`, `get_user_group`, `update_user_group`, `delete_user_group`, and 2 more

## 🔐 OAuth Proxy

**Port:** 3002
**Location:** `/opt/ai-agent-platform/mcp-servers/clickup-mcp/oauth-proxy/`

The OAuth proxy handles GitHub OAuth authentication for ClickUp API access:
- GitHub OAuth integration
- Automatic token refresh
- Multi-user support with SQLite storage
- Secure credential management

See [OAuth documentation](docs/oauth/) for setup details.

## 📊 Testing

All 88 ClickUp MCP tools have been comprehensively tested and verified:
- ✅ Workspace operations
- ✅ Space management (NEW)
- ✅ List and folder management
- ✅ Task CRUD operations
- ✅ Bulk operations
- ✅ Comments and file attachments
- ✅ Time tracking
- ✅ Tag management
- ✅ Custom fields (NEW)
- ✅ Checklists (NEW)
- ✅ Goals and key results (NEW)
- ✅ Dependencies and relationships (NEW)
- ✅ Views (NEW)
- ✅ Webhooks (NEW)
- ✅ Guest management (NEW)

See [Enhancement Status](CLICKUP-MCP-ENHANCEMENT.md) and [Deployment Status](DEPLOYMENT-STATUS.md) for detailed implementation.

## 📝 Maintenance

### Health Checks
```bash
./scripts/health-check-all.sh
```

### View Service Logs
```bash
# On the GCP VM
sudo journalctl -u clickup-mcp -f
sudo journalctl -u clickup-mcp-oauth-proxy -f
```

### Restart Services
```bash
# On the GCP VM
sudo systemctl restart clickup-mcp
sudo systemctl restart clickup-mcp-oauth-proxy
```

## 📖 Additional Resources

- [ClickUp API Documentation](https://clickup.com/api)
- [ClickUp MCP Server GitHub](https://github.com/taazkareem/clickup-mcp-server)
- [MCP Protocol Specification](https://spec.modelcontextprotocol.io/)

## 📅 Deployment History

- **October 9, 2025** - Initial deployment with OAuth proxy (36 tools)
- **October 9, 2025** - Comprehensive testing of all 36 tools
- **October 9, 2025** - Project cleanup and documentation organization
- **October 22, 2025** - Enhanced server deployment with 52 additional tools (88 total)
- **October 22, 2025** - Migrated from original to enhanced server while maintaining OAuth connectivity

---

**Infrastructure**: GCP VM `abound-infra-vm` (us-east1-c, e2-standard-2)
**Maintainer**: Andrew Whalen <andrew@aboundtechology.com>
**Repository**: https://github.com/aboundTechOlogy/clickup-mcp
