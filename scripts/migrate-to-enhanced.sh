#!/bin/bash
set -e

echo "=========================================="
echo "ClickUp MCP Enhanced Server Migration"
echo "=========================================="
echo ""
echo "This script will:"
echo "1. Update OAuth proxy to use enhanced backend (port 3456)"
echo "2. Stop old ClickUp MCP server (port 3003)"
echo "3. Start enhanced ClickUp MCP server (port 3456)"
echo "4. Restart OAuth proxy"
echo ""
echo "⚠️  IMPORTANT: All clients will continue working with NO config changes"
echo "   Clients connect to OAuth proxy (port 3002), which now uses enhanced backend"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Migration cancelled"
    exit 1
fi

VM_NAME="abound-infra-vm"
ZONE="us-east1-c"
PROJECT_ID="abound-infr"

echo ""
echo "Step 1: Updating OAuth proxy load-secrets.sh to use port 3456..."

# Update the OAuth proxy startup script to point to enhanced server
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID -- \
    "sudo sed -i 's|CLICKUP_MCP_URL=http://localhost:3003|CLICKUP_MCP_URL=http://localhost:3456|' \
     /opt/ai-agent-platform/mcp-servers/clickup-mcp/oauth-proxy/load-secrets.sh"

echo "✅ OAuth proxy configured for enhanced backend"
echo ""

echo "Step 2: Stopping old ClickUp MCP server (port 3003)..."
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID -- \
    "sudo systemctl stop clickup-mcp"

echo "✅ Old server stopped"
echo ""

echo "Step 3: Starting enhanced ClickUp MCP server (port 3456)..."
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID -- \
    "sudo systemctl start clickup-mcp-enhanced"

# Wait for server to start
sleep 3

echo "✅ Enhanced server started"
echo ""

echo "Step 4: Restarting OAuth proxy..."
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID -- \
    "sudo systemctl restart clickup-mcp-oauth-proxy"

# Wait for proxy to restart
sleep 3

echo "✅ OAuth proxy restarted"
echo ""

echo "Step 5: Verifying services..."

# Check enhanced server status
echo "Enhanced ClickUp MCP (port 3456):"
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID -- \
    "systemctl is-active clickup-mcp-enhanced && echo '  Status: ✅ Active' || echo '  Status: ❌ Inactive'"

# Check OAuth proxy status
echo "OAuth Proxy (port 3002):"
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID -- \
    "systemctl is-active clickup-mcp-oauth-proxy && echo '  Status: ✅ Active' || echo '  Status: ❌ Inactive'"

# Check old server status (should be inactive)
echo "Old ClickUp MCP (port 3003):"
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID -- \
    "systemctl is-active clickup-mcp && echo '  Status: ⚠️  Still Active (should be stopped)' || echo '  Status: ✅ Stopped'"

echo ""
echo "=========================================="
echo "✅ Migration Complete!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  • Old server (36 tools) on port 3003: STOPPED"
echo "  • Enhanced server (88 tools) on port 3456: RUNNING"
echo "  • OAuth proxy: Updated and RUNNING"
echo ""
echo "Client Impact:"
echo "  • NO configuration changes needed"
echo "  • All clients still connect to: https://clickup-mcp.aboundtechology.com/mcp"
echo "  • OAuth authentication continues working"
echo "  • Bearer token authentication continues working"
echo "  • Clients now have access to 88 tools instead of 36"
echo ""
echo "New Tools Available (52 added):"
echo "  • Space Management (5 tools) - create, list, update, delete spaces"
echo "  • Custom Fields (3 tools) - manage custom field values"
echo "  • Checklists (6 tools) - create and manage task checklists"
echo "  • Goals (7 tools) - workspace goals and key results"
echo "  • Dependencies (4 tools) - task dependencies and relationships"
echo "  • Members/Guests (8 tools) - manage workspace members and guests"
echo "  • Views (6 tools) - create and manage custom views"
echo "  • Webhooks (4 tools) - webhook management"
echo "  • Templates (2 tools) - create from templates"
echo "  • User Groups (3 tools) - manage user groups"
echo "  • + 4 misc tools (shared hierarchy, authorized user, etc.)"
echo ""
echo "Next Steps:"
echo "  1. Test OAuth authentication: Try connecting from Claude Desktop"
echo "  2. Test bearer token: Try from Cursor or Claude Code"
echo "  3. Test new tools: Try creating a space or adding custom fields"
echo "  4. Monitor logs: sudo journalctl -u clickup-mcp-enhanced -f"
echo ""
echo "Rollback (if needed):"
echo "  1. sudo systemctl stop clickup-mcp-enhanced"
echo "  2. sudo systemctl start clickup-mcp"
echo "  3. Edit /opt/ai-agent-platform/mcp-servers/clickup-mcp/oauth-proxy/load-secrets.sh"
echo "     Change: CLICKUP_MCP_URL=http://localhost:3456"
echo "     To:     CLICKUP_MCP_URL=http://localhost:3003"
echo "  4. sudo systemctl restart clickup-mcp-oauth-proxy"
echo ""
