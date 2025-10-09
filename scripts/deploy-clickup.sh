#!/bin/bash
set -e

# ClickUp MCP Deployment Script
# Deploys ClickUp MCP server to GCP VM
# Run this script ON THE VM after secrets are created

PROJECT_ID="abound-infr"
SERVICE_NAME="clickup-mcp"
PORT=3002
INSTALL_DIR="/opt/ai-agent-platform/mcp-servers/clickup-mcp"

echo "========================================"
echo "ClickUp MCP Deployment"
echo "========================================"
echo ""

# Check if running on VM
if [ ! -d "/opt/ai-agent-platform" ]; then
  echo "❌ Error: This script must be run ON the GCP VM"
  echo "   SSH to VM first: gcloud compute ssh abound-infra-vm --zone=us-east1-c --project=abound-infr"
  exit 1
fi

# Get Team ID
echo "Please enter your ClickUp Team ID (from URL: https://app.clickup.com/<TEAM_ID>/...):"
read -p "Team ID: " CLICKUP_TEAM_ID

if [ -z "$CLICKUP_TEAM_ID" ]; then
  echo "❌ Error: Team ID cannot be empty"
  exit 1
fi
echo ""

# Pre-deployment checks
echo "🔍 Pre-deployment checks..."

# Check port availability
if sudo lsof -i :$PORT &>/dev/null; then
  echo "❌ Error: Port $PORT is already in use"
  sudo lsof -i :$PORT
  exit 1
fi
echo "✅ Port $PORT is available"

# Verify secrets access
if ! gcloud secrets versions access latest --secret=clickup-mcp-auth-token --project=$PROJECT_ID &>/dev/null; then
  echo "❌ Error: Cannot access secret 'clickup-mcp-auth-token'"
  echo "   Run setup-clickup-secrets.sh first"
  exit 1
fi
echo "✅ Can access auth token secret"

if ! gcloud secrets versions access latest --secret=clickup-mcp-api-key --project=$PROJECT_ID &>/dev/null; then
  echo "❌ Error: Cannot access secret 'clickup-mcp-api-key'"
  echo "   Run setup-clickup-secrets.sh first"
  exit 1
fi
echo "✅ Can access API key secret"
echo ""

# Create installation directory
echo "📁 Creating installation directory..."
if [ -d "$INSTALL_DIR" ]; then
  echo "⚠️  Directory $INSTALL_DIR already exists"
  read -p "Continue anyway? (y/n): " CONTINUE
  if [ "$CONTINUE" != "y" ]; then
    echo "❌ Deployment cancelled"
    exit 1
  fi
else
  sudo mkdir -p $INSTALL_DIR
  sudo chown -R root:root $INSTALL_DIR
  echo "✅ Created $INSTALL_DIR"
fi
echo ""

# Install package
echo "📦 Installing ClickUp MCP server..."
if sudo npm install -g @taazkareem/clickup-mcp-server@latest; then
  echo "✅ Package installed"
  INSTALLED_VERSION=$(npm list -g @taazkareem/clickup-mcp-server --depth=0 2>/dev/null | grep @taazkareem/clickup-mcp-server || echo "unknown")
  echo "   Version: $INSTALLED_VERSION"
else
  echo "❌ Error: Failed to install package"
  exit 1
fi
echo ""

# Create load-secrets.sh
echo "🔧 Creating load-secrets.sh..."
sudo tee $INSTALL_DIR/load-secrets.sh > /dev/null << EOF
#!/bin/bash
set -e

PROJECT_ID="$PROJECT_ID"
cd $INSTALL_DIR

echo "Loading secrets from Google Secret Manager..."

# Fetch secrets to shell variables (not exported)
CLICKUP_API_KEY=\$(gcloud secrets versions access latest --secret="clickup-mcp-api-key" --project="\$PROJECT_ID")
CLICKUP_TEAM_ID="$CLICKUP_TEAM_ID"
PORT=$PORT

echo "Secrets loaded successfully"
echo "Starting ClickUp MCP server on port \$PORT..."

# Start application using --env flags (package-specific syntax)
exec npx -y @taazkareem/clickup-mcp-server@latest \\
  --env CLICKUP_API_KEY=\$CLICKUP_API_KEY \\
  --env CLICKUP_TEAM_ID=\$CLICKUP_TEAM_ID \\
  --env PORT=\$PORT \\
  --env ENABLE_SSE=true \\
  --env HOST=0.0.0.0 \\
  --env NODE_ENV=production
EOF

sudo chmod +x $INSTALL_DIR/load-secrets.sh
echo "✅ Created load-secrets.sh"
echo ""

# Test load-secrets script
echo "🧪 Testing load-secrets.sh..."
echo "   Starting server in background for 10 seconds..."
sudo $INSTALL_DIR/load-secrets.sh &
SCRIPT_PID=$!
sleep 10

if curl -sf http://localhost:$PORT/health > /dev/null; then
  echo "✅ Server is responding to health checks"
else
  echo "⚠️  Health check failed (this may be normal if server needs more time)"
fi

sudo kill $SCRIPT_PID 2>/dev/null || true
sleep 2
echo ""

# Create systemd service
echo "⚙️  Creating systemd service..."
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << 'EOF'
[Unit]
Description=ClickUp MCP Server
After=network.target
Documentation=https://github.com/taazkareem/clickup-mcp-server

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/ai-agent-platform/mcp-servers/clickup-mcp

# Start via load-secrets.sh which sets environment and runs server
ExecStart=/opt/ai-agent-platform/mcp-servers/clickup-mcp/load-secrets.sh

Restart=always
RestartSec=10

# Security
NoNewPrivileges=true
PrivateTmp=true

# Resources
MemoryLimit=512M
CPUQuota=50%

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=clickup-mcp

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Created systemd service"
echo ""

# Reload systemd
echo "🔄 Reloading systemd..."
sudo systemctl daemon-reload
echo "✅ Systemd reloaded"
echo ""

# Enable and start service
echo "🚀 Enabling and starting service..."
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME
sleep 3
echo ""

# Check service status
echo "📊 Service status:"
sudo systemctl status $SERVICE_NAME --no-pager || true
echo ""

# Verify health
echo "🧪 Testing local health endpoint..."
sleep 5
if curl -sf http://localhost:$PORT/health; then
  echo ""
  echo "✅ Health check passed"
else
  echo ""
  echo "⚠️  Health check failed"
  echo "   Check logs: sudo journalctl -u $SERVICE_NAME -n 50"
fi
echo ""

# Display logs
echo "📝 Recent logs:"
sudo journalctl -u $SERVICE_NAME -n 20 --no-pager
echo ""

# Summary
echo "========================================"
echo "✅ Deployment Complete"
echo "========================================"
echo ""
echo "Service: $SERVICE_NAME"
echo "Port: $PORT"
echo "Install Dir: $INSTALL_DIR"
echo "Team ID: $CLICKUP_TEAM_ID"
echo ""
echo "Service status:"
echo "  sudo systemctl status $SERVICE_NAME"
echo ""
echo "View logs:"
echo "  sudo journalctl -u $SERVICE_NAME -f"
echo ""
echo "Next steps:"
echo "  1. Configure Caddy reverse proxy"
echo "  2. Test external access"
echo "  3. Configure clients (Cursor, Claude Desktop, etc.)"
echo ""
echo "See clickup/DEPLOYMENT.md for detailed steps"
echo ""
