# ClickUp MCP Deployment Status

## Current Deployment (2025-10-22)

### Enhanced Server ✅ DEPLOYED
- **Location**: `/opt/ai-agent-platform/mcp-servers/clickup-mcp-enhanced`
- **Service**: `clickup-mcp-enhanced.service`
- **Port**: 3456
- **Tools**: 90 (36 original + 54 new)
- **Status**: Active and running
- **Endpoints**:
  - Streamable HTTP: `http://127.0.0.1:3456/mcp`
  - Legacy SSE: `http://127.0.0.1:3456/sse`
  - Health check: `http://127.0.0.1:3456/health`

### Original Server (Still Running)
- **Location**: Runs from npx cache
- **Service**: `clickup-mcp.service`
- **Port**: 3003
- **Tools**: 36
- **Status**: Active (for backward compatibility)

## New Tools Added (54 total)

### Space Management (5 tools)
- `create_space` - Create a new space
- `get_spaces` - List all spaces
- `get_space` - Get a specific space
- `update_space` - Update space properties
- `delete_space` - Delete a space

### Custom Fields (3 tools)
- `get_custom_fields` - Get custom fields for a list
- `create_custom_field` - Create a custom field
- `remove_custom_field` - Remove a custom field

### Checklist Management (6 tools)
- `create_checklist` - Create a checklist
- `update_checklist` - Update checklist details
- `delete_checklist` - Delete a checklist
- `create_checklist_item` - Add item to checklist
- `update_checklist_item` - Update checklist item
- `delete_checklist_item` - Remove checklist item

### Goal Management (8 tools)
- `get_goals` - Get all goals
- `get_goal` - Get specific goal details
- `create_goal` - Create a new goal
- `update_goal` - Update goal properties
- `delete_goal` - Delete a goal
- `create_key_result` - Add key result to goal
- `update_key_result` - Update key result
- `delete_key_result` - Remove key result

### Task Dependencies (4 tools)
- `get_task_dependencies` - Get task dependencies
- `add_task_dependency` - Add a dependency
- `remove_task_dependency` - Remove a dependency
- `get_dependent_tasks` - Get tasks dependent on this task

### Member/Guest Management (8 tools)
- `invite_guest_to_workspace` - Invite a guest
- `get_workspace_guests` - List all guests
- `update_guest_permissions` - Update guest access
- `remove_guest` - Remove a guest
- `get_user_groups` - List user groups
- `create_user_group` - Create a user group
- `update_user_group` - Update group details
- `delete_user_group` - Delete a user group

### Views (6 tools)
- `get_list_views` - Get views for a list
- `get_view` - Get specific view details
- `create_view` - Create a new view
- `update_view` - Update view properties
- `delete_view` - Delete a view
- `get_view_tasks` - Get tasks in a view

### Webhooks (4 tools)
- `get_webhooks` - List all webhooks
- `create_webhook` - Create a webhook
- `update_webhook` - Update webhook settings
- `delete_webhook` - Delete a webhook

### Miscellaneous (10 tools)
- `get_shared_hierarchy` - Get shared workspace hierarchy
- `get_task_templates` - Get task templates
- `create_task_from_template` - Create task from template
- `get_user_profile` - Get user profile
- `update_user_profile` - Update user settings
- `get_workspace_plan` - Get workspace subscription plan
- `get_workspace_seats` - Get seat usage
- `get_custom_roles` - Get custom roles
- `create_custom_role` - Create a custom role
- `update_custom_role` - Update role permissions

## Service Management

### Start Enhanced Server
```bash
sudo systemctl start clickup-mcp-enhanced
```

### Stop Enhanced Server
```bash
sudo systemctl stop clickup-mcp-enhanced
```

### Check Status
```bash
sudo systemctl status clickup-mcp-enhanced
```

### View Logs
```bash
sudo journalctl -u clickup-mcp-enhanced -f
```

### Restart Enhanced Server
```bash
sudo systemctl restart clickup-mcp-enhanced
```

## Migration Notes

The enhanced server runs on a different port (3456) than the original (3003), allowing both to coexist during the transition period. To fully migrate:

1. Update any clients to use port 3456 instead of 3003
2. Test all functionality with the enhanced server
3. Once confirmed working, stop the original service:
   ```bash
   sudo systemctl stop clickup-mcp
   sudo systemctl disable clickup-mcp
   ```

## Architecture

The enhanced server includes:
- **8 new service files** in `src/services/clickup/`
- **2 new tool definition files** in `src/tools/`
- **Updated TypeScript types** in `src/services/clickup/types.ts`
- **Build output** in `build/` directory with all 90 tools

## Deployment Script

Location: `/home/dreww/clickup-mcp/scripts/deploy-enhanced-clickup.sh`

This script automates:
1. Local build verification
2. VM directory creation
3. File transfer via gcloud
4. Production dependency installation
5. Systemd service creation
6. Startup script generation
7. Service enablement

## Next Steps

1. Test all 54 new tools to ensure they work correctly
2. Update client configurations to use port 3456
3. Update documentation to reflect 90 tools
4. Monitor logs for any issues
5. Once stable, deprecate the original service
