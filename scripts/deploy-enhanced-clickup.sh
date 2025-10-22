#!/bin/bash
set -e

# Enhanced ClickUp MCP Server Deployment Script
# Deploys the locally enhanced clickup-mcp-server to GCP VM

PROJECT_ID="abound-infr"
VM_NAME="abound-infra-vm"
ZONE="us-east1-c"
VM_PATH="/opt/ai-agent-platform/mcp-servers/clickup-mcp-enhanced"
LOCAL_BUILD_DIR="clickup-mcp-server"

echo "========================================="
echo "Enhanced ClickUp MCP Server Deployment"
echo "========================================="
echo ""

# Step 1: Verify build exists locally
echo "Step 1: Verifying local build..."
if [ ! -d "$LOCAL_BUILD_DIR/build" ]; then
    echo "❌ Build directory not found. Running npm build..."
    cd "$LOCAL_BUILD_DIR"
    npm run build
    cd ..
fi
echo "✅ Build verified"
echo ""

# Step 2: Create deployment directory on VM
echo "Step 2: Creating deployment directory on VM..."
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID -- \
    "sudo mkdir -p $VM_PATH && sudo chown dreww:dreww $VM_PATH"
echo "✅ Directory created"
echo ""

# Step 3: Copy enhanced server to VM
echo "Step 3: Copying enhanced server files to VM..."
gcloud compute scp --recurse \
    $LOCAL_BUILD_DIR/build \
    $LOCAL_BUILD_DIR/package.json \
    $LOCAL_BUILD_DIR/package-lock.json \
    ${VM_NAME}:${VM_PATH}/ \
    --zone=$ZONE \
    --project=$PROJECT_ID
echo "✅ Files copied"
echo ""

# Step 4: Install dependencies on VM (skip prepare script)
echo "Step 4: Installing dependencies on VM..."
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID -- \
    "cd $VM_PATH && npm install --production --ignore-scripts"
echo "✅ Dependencies installed"
echo ""

# Step 5: Create systemd service file
echo "Step 5: Creating enhanced systemd service..."
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID -- "sudo tee /etc/systemd/system/clickup-mcp-enhanced.service" << 'EOF'
[Unit]
Description=Enhanced ClickUp MCP Server (90 tools)
After=network.target
Documentation=https://github.com/aboundTechOlogy/clickup-mcp

[Service]
Type=simple
User=dreww
Group=dreww
WorkingDirectory=/opt/ai-agent-platform/mcp-servers/clickup-mcp-enhanced

# Load secrets and start
ExecStart=/opt/ai-agent-platform/mcp-servers/clickup-mcp-enhanced/start-enhanced.sh

Restart=always
RestartSec=10

NoNewPrivileges=true
PrivateTmp=true

MemoryLimit=512M
CPUQuota=50%

StandardOutput=journal
StandardError=journal
SyslogIdentifier=clickup-mcp-enhanced

[Install]
WantedBy=multi-user.target
EOF
echo "✅ Service file created"
echo ""

# Step 6: Create start script on VM
echo "Step 6: Creating startup script on VM..."
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID -- \
    "cat > $VM_PATH/start-enhanced.sh" << 'EOF'
#!/bin/bash
set -e

PROJECT_ID="abound-infr"
cd /opt/ai-agent-platform/mcp-servers/clickup-mcp-enhanced

echo "Loading secrets from Google Secret Manager..."

# Fetch secrets
CLICKUP_API_KEY=$(gcloud secrets versions access latest --secret="clickup-mcp-api-key" --project="$PROJECT_ID")
CLICKUP_TEAM_ID="90132011383"
PORT=3456
AUTH_TOKEN=$(gcloud secrets versions access latest --secret="clickup-mcp-auth-token" --project="$PROJECT_ID")

echo "Secrets loaded successfully"
echo "Starting Enhanced ClickUp MCP server on port $PORT with 90 tools..."

# Set environment variables and start
export CLICKUP_API_KEY="$CLICKUP_API_KEY"
export CLICKUP_TEAM_ID="$CLICKUP_TEAM_ID"
export PORT="$PORT"
export ENABLE_SSE=true
export HOST="0.0.0.0"
export NODE_ENV=production
export AUTH_TOKEN="$AUTH_TOKEN"

exec node build/index.js
EOF
echo "✅ Start script created"
echo ""

# Step 7: Make start script executable
echo "Step 7: Making start script executable..."
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID -- \
    "chmod +x $VM_PATH/start-enhanced.sh"
echo "✅ Script made executable"
echo ""

# Step 8: Reload systemd and enable service
echo "Step 8: Enabling enhanced service..."
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID -- \
    "sudo systemctl daemon-reload && sudo systemctl enable clickup-mcp-enhanced.service"
echo "✅ Service enabled"
echo ""

echo "========================================="
echo "✅ Enhanced ClickUp MCP Server Deployed!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Stop old service: sudo systemctl stop clickup-mcp"
echo "2. Start new service: sudo systemctl start clickup-mcp-enhanced"
echo "3. Check status: sudo systemctl status clickup-mcp-enhanced"
echo "4. View logs: sudo journalctl -u clickup-mcp-enhanced -f"
echo ""
echo "The enhanced server will run on port 3456 with 90 tools (36 original + 54 new)"
echo ""
