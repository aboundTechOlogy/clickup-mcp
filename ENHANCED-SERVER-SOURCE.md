# Enhanced ClickUp MCP Server Source Code

## Overview

The enhanced ClickUp MCP server with 88 tools is built from a modified version of the upstream `@taazkareem/clickup-mcp-server` repository.

## Source Code Location

**On VM:** `/opt/ai-agent-platform/mcp-servers/clickup-mcp-enhanced/`

**Local Development:** The source code is in `clickup-mcp-server/` directory (git-ignored, not committed to this repo)

## Repository

- **Enhanced Fork:** https://github.com/aboundTechOlogy/clickup-mcp-server (88 tools)
- **Original Upstream:** https://github.com/taazkareem/clickup-mcp-server (36 tools)
- **Forked From:** v0.8.5 (October 22, 2025)

## Enhancement Details

### What Was Added (52 New Tools)

1. **Space Management (5 tools)**
   - Files: `src/tools/space.ts`, `src/services/clickup/workspace.ts` (modified)

2. **Custom Fields (3 tools)**
   - Files: `src/services/clickup/custom-fields.ts`, `src/tools/all-new-tools.ts`

3. **Checklists (6 tools)**
   - Files: `src/services/clickup/checklist.ts`, `src/tools/all-new-tools.ts`

4. **Goals (7 tools)**
   - Files: `src/services/clickup/goal.ts`, `src/tools/all-new-tools.ts`

5. **Dependencies (4 tools)**
   - Files: `src/services/clickup/dependency.ts`, `src/tools/all-new-tools.ts`

6. **Members & Guests (8 tools)**
   - Files: `src/services/clickup/guest.ts`, `src/tools/all-new-tools.ts`

7. **Views (6 tools)**
   - Files: `src/services/clickup/view.ts`, `src/tools/all-new-tools.ts`

8. **Webhooks (4 tools)**
   - Files: `src/services/clickup/webhook.ts`, `src/tools/all-new-tools.ts`

9. **User Management (3 tools)**
   - Files: `src/services/clickup/user.ts`, `src/tools/all-new-tools.ts`

10. **Miscellaneous (6 tools)**
    - Shared hierarchy, templates, user groups, etc.

### Modified Files

```
src/
├── services/clickup/
│   ├── types.ts                 # Added new TypeScript types
│   ├── workspace.ts             # Added createSpace, updateSpace, deleteSpace
│   ├── index.ts                 # Export new services
│   ├── custom-fields.ts         # NEW
│   ├── checklist.ts             # NEW
│   ├── goal.ts                  # NEW
│   ├── dependency.ts            # NEW
│   ├── guest.ts                 # NEW
│   ├── view.ts                  # NEW
│   ├── webhook.ts               # NEW
│   └── user.ts                  # NEW
└── tools/
    ├── index.ts                 # Export new tool files
    ├── space.ts                 # NEW - 5 space tools
    └── all-new-tools.ts         # NEW - 47 additional tools
```

## Building the Enhanced Server

From the `clickup-mcp-server/` directory:

```bash
npm install
npm run build
```

Output goes to `build/` directory.

## Deployment

The enhanced server is deployed using:
```bash
./scripts/deploy-enhanced-clickup.sh
```

This script:
1. Builds the enhanced server locally
2. Copies build output to VM
3. Installs production dependencies
4. Creates systemd service
5. Starts the enhanced server

## Migration to Enhanced Server

The migration script switches from the old to enhanced server:
```bash
./scripts/migrate-to-enhanced.sh
```

This script:
1. Updates OAuth proxy to point to enhanced backend (port 3456)
2. Stops old server (port 3003)
3. Starts enhanced server (port 3456)
4. Restarts OAuth proxy

**Important:** All OAuth and client connectivity is preserved because the OAuth proxy remains unchanged.

## Future Maintenance

### Keeping Up with Upstream

To merge updates from the original repository:

```bash
cd clickup-mcp-server
git remote add upstream https://github.com/taazkareem/clickup-mcp-server.git
git fetch upstream
git merge upstream/main
# Resolve any conflicts with our enhancements
npm run build
./scripts/deploy-enhanced-clickup.sh
```

### Cloning the Enhanced Server

To get the enhanced server source code:

```bash
git clone https://github.com/aboundTechOlogy/clickup-mcp-server.git
cd clickup-mcp-server
npm install
npm run build
```

## Architecture Notes

The enhanced server is a **drop-in replacement** for the original server because:
- Same HTTP/SSE endpoints
- Same MCP protocol implementation
- Same authentication (bearer token)
- Just more tools available

The OAuth proxy doesn't need any modifications - it simply forwards requests to whichever backend is configured in `CLICKUP_MCP_URL`.

## Testing

All 88 tools have been tested and verified working. See:
- [CLICKUP-MCP-ENHANCEMENT.md](CLICKUP-MCP-ENHANCEMENT.md) - Full list of added tools
- [DEPLOYMENT-STATUS.md](DEPLOYMENT-STATUS.md) - Current deployment status

## Rollback

If needed, rollback to the original 36-tool server:

```bash
sudo systemctl stop clickup-mcp-enhanced
sudo systemctl start clickup-mcp
# Edit /opt/ai-agent-platform/mcp-servers/clickup-mcp/oauth-proxy/load-secrets.sh
# Change: CLICKUP_MCP_URL=http://localhost:3456
# To:     CLICKUP_MCP_URL=http://localhost:3003
sudo systemctl restart clickup-mcp-oauth-proxy
```

---

**Last Updated:** October 22, 2025
