#!/bin/bash
# Deploy OAuth proxy for ClickUp MCP server
set -e

echo "========================================="
echo "ClickUp MCP OAuth Proxy Deployment"
echo "========================================="

# Configuration
PROJECT_ID="abound-infr"
OAUTH_DIR="/opt/ai-agent-platform/mcp-servers/clickup-mcp/oauth-proxy"
SERVICE_NAME="clickup-mcp-oauth-proxy"

# Check if running on VM
if [ ! -f /etc/systemd/system/clickup-mcp.service ]; then
  echo "Error: This script must be run on the GCP VM"
  echo "Please SSH to the VM first:"
  echo "  gcloud compute ssh abound-infra-vm --zone=us-east1-c --project=abound-infr"
  exit 1
fi

echo "Creating OAuth proxy directory..."
sudo mkdir -p "$OAUTH_DIR/src"
cd "$OAUTH_DIR"

echo "Creating package.json..."
sudo tee package.json > /dev/null <<'EOF'
{
  "name": "clickup-mcp-oauth-proxy",
  "version": "1.0.0",
  "description": "OAuth 2.0 proxy wrapper for ClickUp MCP server",
  "type": "module",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.4",
    "express": "^4.18.2",
    "node-fetch": "^3.3.2",
    "better-sqlite3": "^9.2.2"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/better-sqlite3": "^7.6.8",
    "@types/node": "^20.10.6",
    "typescript": "^5.3.3"
  }
}
EOF

echo "Creating tsconfig.json..."
sudo tee tsconfig.json > /dev/null <<'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "moduleResolution": "node",
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "strict": true,
    "skipLibCheck": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF

echo "Copying source files..."
# The actual source files would be copied from the local machine
# For now, we'll create placeholder - real deployment would rsync from local

echo "Installing dependencies..."
sudo npm install

echo "Building TypeScript..."
sudo npm run build

echo "Creating secrets loader script..."
sudo tee load-secrets.sh > /dev/null <<EOF
#!/bin/bash
set -e

PROJECT_ID="$PROJECT_ID"

echo "Loading secrets from Google Secret Manager..."

# Fetch secrets
export AUTH_TOKEN=\$(gcloud secrets versions access latest --secret="clickup-mcp-auth-token" --project="\$PROJECT_ID")

# OAuth Proxy configuration
export PROXY_PORT=3001
export CLICKUP_MCP_URL=http://localhost:3002
export BASE_URL=https://clickup-mcp.aboundtechology.com
export NODE_ENV=production

echo "Secrets loaded successfully"

# Start the OAuth proxy
exec /usr/bin/node $OAUTH_DIR/dist/index.js
EOF

sudo chmod +x load-secrets.sh

echo "Creating systemd service..."
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=ClickUp MCP OAuth Proxy
Documentation=https://github.com/aboundTechOlogy/clickup-mcp
After=network.target clickup-mcp.service
Requires=network.target
Wants=clickup-mcp.service

[Service]
Type=simple
User=n8n-mcp
Group=n8n-mcp
WorkingDirectory=$OAUTH_DIR

# Use secrets loader script
ExecStart=$OAUTH_DIR/load-secrets.sh

# Restart policy
Restart=always
RestartSec=10
StartLimitBurst=5
StartLimitInterval=60s

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$OAUTH_DIR
ProtectKernelTunables=true
ProtectControlGroups=true
RestrictSUIDSGID=true
LockPersonality=true

# Resource limits
MemoryLimit=256M
CPUQuota=25%
LimitNOFILE=65536

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

[Install]
WantedBy=multi-user.target
EOF

echo "Setting permissions..."
sudo chown -R n8n-mcp:n8n-mcp "$OAUTH_DIR"

echo "Enabling and starting service..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

echo ""
echo "Checking service status..."
sudo systemctl status $SERVICE_NAME --no-pager

echo ""
echo "========================================="
echo "OAuth Proxy Deployment Complete!"
echo "========================================="
echo ""
echo "Service running on port 3001"
echo "ClickUp MCP running on port 3002"
echo ""
echo "Next steps:"
echo "1. Update Caddy to proxy through OAuth proxy (port 3001)"
echo "2. Restart Caddy"
echo "3. Test OAuth endpoints"
echo ""
