# ClickUp MCP Enhancement Project

**Project Code**: ATO-INFRA-2025-10-ClickUpMCP
**Status**: In Progress - Research Complete
**Started**: October 21, 2025
**Owner**: Andrew Whalen
**Blocks**: ATO-PLATFORM-SETUP.md

## Project Overview

Enhance the clickup-mcp server by adding ALL missing ClickUp API endpoints to create a complete, production-ready MCP server for ClickUp integration.

## Current State

### Existing Tools (36 tools)
✅ Tasks (create, get, update, delete, bulk operations)
✅ Comments (get, create)
✅ Attachments (attach file)
✅ Time Tracking (6 tools)
✅ Lists (create, get, update, delete, create in folder)
✅ Folders (create, get, update, delete)
✅ Tags (list, create, delete, add to task, remove from task)
✅ Workspace (get hierarchy, get members)
✅ Search (get workspace tasks with filters)

### Missing Tools (54 tools to add)

## Tools to Add

### 1. Spaces (5 tools) - CRITICAL BLOCKER
```
- create_space
- get_spaces (list all)
- get_space (single)
- update_space
- delete_space
```

**API Endpoints:**
- POST `/api/v2/team/{team_id}/space` - Create Space
- GET `/api/v2/team/{team_id}/space` - Get Spaces (list)
- GET `/api/v2/space/{space_id}` - Get Space (single)
- PUT `/api/v2/space/{space_id}` - Update Space
- DELETE `/api/v2/space/{space_id}` - Delete Space

**Documentation:**
- https://developer.clickup.com/reference/createspace
- https://developer.clickup.com/reference/getspaces
- https://developer.clickup.com/reference/getspace
- https://developer.clickup.com/reference/updatespace
- https://developer.clickup.com/reference/deletespace

### 2. Custom Fields (3 tools) - HIGH PRIORITY
```
- get_accessible_custom_fields
- set_custom_field_value
- remove_custom_field_value
```

**API Endpoints:**
- GET `/api/v2/list/{list_id}/field` - Get accessible custom fields
- POST `/api/v2/task/{task_id}/field/{field_id}` - Set custom field value
- DELETE `/api/v2/task/{task_id}/field/{field_id}` - Remove custom field value

**Note:** Creating/editing custom field definitions NOT supported by API

### 3. Checklists (6 tools)
```
- create_checklist
- update_checklist
- delete_checklist
- create_checklist_item
- update_checklist_item
- delete_checklist_item
```

**API Endpoints:**
- POST `/api/v2/task/{task_id}/checklist` - Create checklist
- PUT `/api/v2/checklist/{checklist_id}` - Update checklist
- DELETE `/api/v2/checklist/{checklist_id}` - Delete checklist
- POST `/api/v2/checklist/{checklist_id}/checklist_item` - Create item
- PUT `/api/v2/checklist/{checklist_id}/checklist_item/{checklist_item_id}` - Update item
- DELETE `/api/v2/checklist/{checklist_id}/checklist_item/{checklist_item_id}` - Delete item

### 4. Goals (7 tools)
```
- create_goal
- get_goal
- update_goal
- delete_goal
- get_goals (list)
- create_key_result
- update_key_result
- delete_key_result
```

**API Endpoints:**
- POST `/api/v2/team/{team_id}/goal` - Create goal
- GET `/api/v2/goal/{goal_id}` - Get goal
- PUT `/api/v2/goal/{goal_id}` - Update goal
- DELETE `/api/v2/goal/{goal_id}` - Delete goal
- GET `/api/v2/team/{team_id}/goal` - Get goals
- POST `/api/v2/goal/{goal_id}/key_result` - Create key result
- PUT `/api/v2/key_result/{key_result_id}` - Update key result
- DELETE `/api/v2/key_result/{key_result_id}` - Delete key result

### 5. Task Relationships/Dependencies (4 tools)
```
- add_dependency
- delete_dependency
- add_task_link
- delete_task_link
```

**API Endpoints:**
- POST `/api/v2/task/{task_id}/dependency` - Add dependency
- DELETE `/api/v2/task/{task_id}/dependency` - Delete dependency
- POST `/api/v2/task/{task_id}/link/{links_to}` - Add task link
- DELETE `/api/v2/task/{task_id}/link/{links_to}` - Delete task link

**Note:** GET task already returns relationships in response

### 6. Members & Guests (8 tools)
```
- get_task_members
- get_list_members
- invite_guest_to_workspace
- edit_guest_on_workspace
- remove_guest_from_workspace
- get_guest
- invite_guest_to_task
- remove_guest_from_task
```

**API Endpoints:**
- GET `/api/v2/task/{task_id}/member` - Get task members
- GET `/api/v2/list/{list_id}/member` - Get list members
- POST `/api/v2/team/{team_id}/guest` - Invite guest to workspace
- PUT `/api/v2/team/{team_id}/guest/{guest_id}` - Edit guest
- DELETE `/api/v2/team/{team_id}/guest/{guest_id}` - Remove guest
- GET `/api/v2/team/{team_id}/guest/{guest_id}` - Get guest
- POST `/api/v2/task/{task_id}/guest/{guest_id}` - Invite guest to task
- DELETE `/api/v2/task/{task_id}/guest/{guest_id}` - Remove guest from task

### 7. Views (5 tools)
```
- create_view
- get_view
- update_view
- delete_view
- get_views (list)
- get_view_tasks
```

**API Endpoints:**
- POST `/api/v2/{parent_type}/{parent_id}/view` - Create view
- GET `/api/v2/view/{view_id}` - Get view
- PUT `/api/v2/view/{view_id}` - Update view
- DELETE `/api/v2/view/{view_id}` - Delete view
- GET `/api/v2/{parent_type}/{parent_id}/view` - Get views
- GET `/api/v2/view/{view_id}/task` - Get view tasks

### 8. Webhooks (4 tools)
```
- create_webhook
- update_webhook
- delete_webhook
- get_webhooks (list)
```

**API Endpoints:**
- POST `/api/v2/team/{team_id}/webhook` - Create webhook
- PUT `/api/v2/webhook/{webhook_id}` - Update webhook
- DELETE `/api/v2/webhook/{webhook_id}` - Delete webhook
- GET `/api/v2/team/{team_id}/webhook` - Get webhooks

### 9. Shared Hierarchy (1 tool)
```
- get_shared_hierarchy
```

**API Endpoints:**
- GET `/api/v2/team/{team_id}/shared` - Get shared hierarchy

### 10. Templates (2 tools)
```
- create_folder_from_template
- create_list_from_template
```

**API Endpoints:**
- POST `/api/v2/space/{space_id}/folder` - Create folder from template
- POST `/api/v2/folder/{folder_id}/list` - Create list from template

**Note:** Templates must exist in workspace first

### 11. Docs (5 tools)
```
- create_doc
- get_doc
- update_doc
- delete_doc
- get_docs (list)
```

**API Endpoints:**
- POST `/api/v3/workspaces/{workspace_id}/docs` - Create doc
- GET `/api/v3/docs/{doc_id}` - Get doc
- PUT `/api/v3/docs/{doc_id}` - Update doc
- DELETE `/api/v3/docs/{doc_id}` - Delete doc
- GET `/api/v3/workspaces/{workspace_id}/docs` - Get docs

### 12. Users (1 tool)
```
- get_authorized_user
```

**API Endpoints:**
- GET `/api/v2/user` - Get authorized user (current user info)

### 13. User Groups (3 tools)
```
- create_user_group
- get_user_group
- update_user_group
- delete_user_group
```

**API Endpoints:**
- POST `/api/v2/team/{team_id}/group` - Create user group
- GET `/api/v2/group/{group_id}` - Get user group
- PUT `/api/v2/group/{group_id}` - Update user group
- DELETE `/api/v2/group/{group_id}` - Delete user group

## Total New Tools: 54

## Implementation Approach

### Phase 1: Setup & Architecture
1. Locate clickup-mcp source code (deployed on infrastructure)
2. Review existing code structure
3. Set up development environment
4. Create branch for enhancement

### Phase 2: Implementation
1. Add all 54 tool definitions
2. Implement API calls for each endpoint
3. Add proper error handling
4. Add TypeScript types for all requests/responses
5. Update documentation

### Phase 3: Testing
1. Unit tests for each new tool
2. Integration tests with live ClickUp API
3. Test all tools via MCP protocol
4. Verify tool descriptions and parameters

### Phase 4: Deployment
1. Build and package updated server
2. Deploy to GCP infrastructure
3. Update MCP server configuration
4. Reload in Claude Desktop
5. Verify all 90 tools (36 existing + 54 new) available

## Technical Notes

### ClickUp API Authentication
- Uses API token in Authorization header
- Token stored in GCP Secret Manager: `clickup-token-production`
- Multi-workspace support via team_id parameter

### ClickUp API Terminology
- **Team** (API v2) = **Workspace** (UI)
- API v3 uses "Workspace" terminology consistently
- Some endpoints use v2, some use v3

### API Limitations Identified
- ❌ Cannot create custom field DEFINITIONS via API (only set values)
- ❌ Cannot create custom task types via API
- ❌ Cannot create automations via API
- ✅ All other CRUD operations supported

## Expected Outcomes

### Before Enhancement
- 36 tools available
- Cannot create Spaces (BLOCKER for ATO project)
- Cannot manage custom fields
- Limited webhook support
- No goals/views/docs support

### After Enhancement
- 90 tools available (36 + 54)
- ✅ Complete Space management
- ✅ Complete custom field value management
- ✅ Full webhook support for automation
- ✅ Goals, views, checklists, dependencies
- ✅ Complete ClickUp API coverage (except documented limitations)

## Dependencies

**Required:**
- ClickUp API access (have token in secrets)
- clickup-mcp source code location
- GCP deployment access
- TypeScript/Node.js development environment

**Blocks:**
- ATO-PLATFORM-SETUP.md (cannot proceed without Space creation tools)

## Next Steps

1. ✅ Research complete - documented all 54 missing tools
2. ⏳ Locate clickup-mcp source code
3. ⏳ Set up development environment
4. ⏳ Implement all 54 tools
5. ⏳ Test thoroughly
6. ⏳ Deploy to production
7. ⏳ Unblock ATO platform setup project

## Resources

### ClickUp API Documentation
- Main docs: https://developer.clickup.com
- API Reference: https://clickup.com/api/clickupreference/overview/
- Postman Collection: ClickUp API v2 Reference

### Current Infrastructure
- MCP Server URL: https://clickup-mcp.aboundtechology.com/mcp (HTTP mode)
- Deployed on: abound-infra-vm (GCP)
- Current version: Unknown (need to check source)
- Sponsor: @taazkareem (community version)

### Related Documentation
- INVENTORY/installed-mcp-servers.md - Current MCP server inventory
- PROJECTS/ATO-PLATFORM-SETUP.md - Main project being blocked

## Notes

- Community clickup-mcp server exists but may not have all tools
- May need to fork and enhance or build from scratch
- Need to verify if we're using community version or custom deployment
- All tools should follow consistent naming convention (verb_noun)
- Include comprehensive JSDoc comments for each tool
- Follow MCP protocol specifications for tool definitions
