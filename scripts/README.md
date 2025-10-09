# Deployment Helper Scripts

This directory contains helper scripts for deploying MCP servers to GCP VM.

## 📁 Scripts Overview

### 1. `setup-clickup-secrets.sh`
**Purpose:** Create and configure secrets in Google Secret Manager for ClickUp MCP server

**Usage:**
```bash
./scripts/setup-clickup-secrets.sh
```

**What it does:**
- Gets VM service account
- Creates `clickup-mcp-auth-token` secret (auto-generated)
- Creates `clickup-mcp-api-key` secret (you provide)
- Grants VM access to secrets
- Tests secret access

**Run from:** Local machine (with gcloud configured)

**Prerequisites:**
- gcloud CLI installed and authenticated
- ClickUp API key (from https://app.clickup.com/settings/apps)
- IAM permissions to create secrets and grant access

---

### 2. `deploy-clickup.sh`
**Purpose:** Deploy ClickUp MCP server on the GCP VM

**Usage:**
```bash
# SSH to VM first
gcloud compute ssh abound-infra-vm --zone=us-east1-c --project=abound-infr

# Then run the script
./scripts/deploy-clickup.sh
```

**What it does:**
- Validates pre-deployment requirements
- Creates installation directory
- Installs npm package globally
- Creates `load-secrets.sh` script
- Creates systemd service
- Starts and enables service
- Tests health endpoint

**Run from:** GCP VM (after SSH)

**Prerequisites:**
- Secrets created (run `setup-clickup-secrets.sh` first)
- ClickUp Team ID
- VM has npm installed

---

### 3. `health-check-all.sh`
**Purpose:** Check health status of all MCP services

**Usage:**
```bash
# Local health checks
./scripts/health-check-all.sh

# Local + external health checks
./scripts/health-check-all.sh --external
```

**What it does:**
- Tests health endpoints for all services
- Shows which services are running
- Displays HTTP response codes
- Provides summary of passing/failing services

**Run from:** GCP VM

**Checks these services:**
- n8n-mcp (port 3000)
- clickup-mcp (port 3002)
- notion-mcp (port 3003)
- google-workspace-mcp (port 3004)
- github-mcp (port 3005)

**Output example:**
```
MCP Services Health Check
=========================================

Local Health Checks (http://localhost):
----------------------------------------
n8n-mcp                   port 3000   ✅ OK (HTTP 200)
clickup-mcp               port 3002   ✅ OK (HTTP 200)
notion-mcp                port 3003   ⏭️  SKIP (not running)
google-workspace-mcp      port 3004   ⏭️  SKIP (not running)
github-mcp                port 3005   ⏭️  SKIP (not running)

Summary:
--------
Total services: 5
Passing: 2
Failing: 0
Skipped: 3
```

---

### 4. `test-mcp-endpoint.sh`
**Purpose:** Test MCP JSON-RPC endpoint functionality

**Usage:**
```bash
# Test local endpoint
./scripts/test-mcp-endpoint.sh clickup-mcp

# Test external endpoint
./scripts/test-mcp-endpoint.sh clickup-mcp --external
```

**What it does:**
- Fetches auth token from Secret Manager
- Tests `tools/list` method
- Tests `resources/list` method (if supported)
- Tests `prompts/list` method (if supported)
- Displays JSON-RPC responses

**Run from:** GCP VM (or local machine for external tests)

**Available services:**
- `n8n-mcp`
- `clickup-mcp`
- `notion-mcp`
- `google-workspace-mcp`
- `github-mcp`

**Output example:**
```
Testing MCP Endpoint: clickup-mcp
=========================================

🔑 Fetching auth token from Secret Manager...
✅ Auth token retrieved

🏠 Testing local endpoint: http://localhost:3002/mcp

Test 1: Listing available tools
--------------------------------
Response:
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "tools": [
      {
        "name": "get_task",
        "description": "Get details of a specific task",
        ...
      }
    ]
  }
}

✅ tools/list succeeded
   Available tools: 8
```

---

## 🔄 Typical Deployment Workflow

### Complete ClickUp Deployment

1. **Create secrets** (run from local machine):
   ```bash
   ./scripts/setup-clickup-secrets.sh
   ```

2. **Deploy service** (run on VM):
   ```bash
   gcloud compute ssh abound-infra-vm --zone=us-east1-c --project=abound-infr
   cd /path/to/project
   ./scripts/deploy-clickup.sh
   ```

3. **Configure Caddy** (manual step on VM):
   - Add Caddy configuration for `clickup-mcp.aboundtechology.com`
   - Restart Caddy: `docker restart n8n-proxy-caddy-1`

4. **Verify deployment** (run on VM):
   ```bash
   # Check health
   ./scripts/health-check-all.sh

   # Test MCP endpoint
   ./scripts/test-mcp-endpoint.sh clickup-mcp

   # Test external access
   ./scripts/test-mcp-endpoint.sh clickup-mcp --external
   ```

5. **Monitor service**:
   ```bash
   sudo systemctl status clickup-mcp
   sudo journalctl -u clickup-mcp -f
   ```

---

## 🔧 Troubleshooting

### Secrets Access Denied
```bash
# Check IAM policy
gcloud secrets get-iam-policy clickup-mcp-auth-token --project=abound-infr

# Grant access manually
VM_SERVICE_ACCOUNT=$(gcloud compute instances describe abound-infra-vm \
  --zone=us-east1-c \
  --format='get(serviceAccounts[0].email)' \
  --project=abound-infr)

gcloud secrets add-iam-policy-binding clickup-mcp-auth-token \
  --member="serviceAccount:$VM_SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor" \
  --project=abound-infr
```

### Service Won't Start
```bash
# Check logs
sudo journalctl -u clickup-mcp -n 50

# Check port availability
sudo lsof -i :3002

# Restart service
sudo systemctl restart clickup-mcp
```

### Health Check Fails
```bash
# Test directly
curl http://localhost:3002/health

# Check if service is running
sudo systemctl status clickup-mcp

# Check if port is listening
sudo netstat -tlnp | grep 3002
```

---

## 📚 Additional Resources

- [clickup/DEPLOYMENT.md](../clickup/DEPLOYMENT.md) - Complete ClickUp deployment guide
- [DEPLOYMENT_PLAN_V2.md](../DEPLOYMENT_PLAN_V2.md) - Overall deployment strategy
- [README.md](../README.md) - Project overview

---

## 🎯 Future Scripts

Scripts to add for other services:
- `setup-notion-secrets.sh`
- `deploy-notion.sh`
- `setup-google-workspace-secrets.sh`
- `deploy-google-workspace.sh`
- `deploy-github.sh`

Pattern scripts:
- `create-service-template.sh` - Generate scripts for new services
- `backup-secrets.sh` - Export secret names and metadata
- `test-all-endpoints.sh` - Test all services at once
