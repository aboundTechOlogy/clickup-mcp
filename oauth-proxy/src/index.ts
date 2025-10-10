import express from 'express';
import { mcpAuthRouter } from '@modelcontextprotocol/sdk/server/auth/router.js';
import { GitHubOAuthProvider } from './github-oauth-provider.js';
import fetch from 'node-fetch';
import { randomUUID } from 'node:crypto';

const app = express();
app.use(express.json());

// Add CORS middleware to expose MCP session headers
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept, Mcp-Session-Id');
  res.setHeader('Access-Control-Expose-Headers', 'Mcp-Session-Id, X-OAuth-Authorization-Server');

  // Don't auto-respond to OPTIONS here - let route handlers do it
  next();
});

// Store session IDs per token (in-memory for now)
// Map: token -> session ID
const sessionStore = new Map<string, string>();

const PORT = parseInt(process.env.PROXY_PORT || '3002');
const CLICKUP_MCP_URL = process.env.CLICKUP_MCP_URL || 'http://localhost:3003';
const BASE_URL = process.env.BASE_URL || `http://localhost:${PORT}`;
const GITHUB_CLIENT_ID = process.env.GITHUB_CLIENT_ID;
const GITHUB_CLIENT_SECRET = process.env.GITHUB_CLIENT_SECRET;

console.log('Starting ClickUp MCP OAuth Proxy with GitHub OAuth...');
console.log('Port:', PORT);
console.log('ClickUp MCP URL:', CLICKUP_MCP_URL);
console.log('Base URL:', BASE_URL);

if (!GITHUB_CLIENT_ID || !GITHUB_CLIENT_SECRET) {
  console.error('ERROR: GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET are required');
  process.exit(1);
}

// Initialize GitHub OAuth provider
const provider = new GitHubOAuthProvider({
  githubClientId: GITHUB_CLIENT_ID,
  githubClientSecret: GITHUB_CLIENT_SECRET,
  baseUrl: BASE_URL
});

// Add MCP OAuth routes
app.use(mcpAuthRouter({
  provider,
  issuerUrl: new URL(BASE_URL),
  scopesSupported: ['mcp:tools', 'mcp:read', 'mcp:write'],
  resourceName: 'ClickUp MCP Server',
}));

// Add GitHub OAuth callback endpoint
app.get('/oauth/callback', async (req, res) => {
  const code = req.query.code as string;
  const state = req.query.state as string;

  if (!code || !state) {
    console.error('GitHub OAuth callback missing code or state');
    res.status(400).send('Missing code or state parameter');
    return;
  }

  try {
    const result = await provider.handleGitHubCallback(code, state);

    // Redirect back to client with authorization code
    const redirectUrl = new URL(result.redirectUri);
    redirectUrl.searchParams.set('code', result.authCode);
    if (result.clientState) {
      redirectUrl.searchParams.set('state', result.clientState);
    }

    console.log('GitHub OAuth callback successful, redirecting to client');
    res.redirect(redirectUrl.toString());
  } catch (error) {
    console.error('GitHub OAuth callback failed:', error);
    res.status(500).send('OAuth authentication failed');
  }
});

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    const response = await fetch(`${CLICKUP_MCP_URL}/health`);
    const data = await response.json() as any;
    res.json({
      proxy: 'ok',
      oauth: 'github',
      clickupMcp: data
    });
  } catch (error) {
    res.status(503).json({
      proxy: 'ok',
      oauth: 'github',
      clickupMcp: 'unreachable',
      error: (error as Error).message
    });
  }
});

// MCP endpoint - proxy to ClickUp MCP with OAuth token validation
app.all('/mcp', async (req, res) => {
  // Handle OPTIONS request for OAuth discovery
  if (req.method === 'OPTIONS') {
    res.setHeader('X-OAuth-Authorization-Server', `${BASE_URL}/.well-known/oauth-authorization-server`);
    res.sendStatus(200);
    return;
  }

  try {
    // Extract token from Authorization header
    const authHeader = req.headers.authorization;
    let token: string | undefined;

    if (authHeader?.startsWith('Bearer ')) {
      token = authHeader.substring(7);
    }

    // Get the ClickUp MCP auth token for comparison
    const clickupAuthToken = process.env.AUTH_TOKEN;

    // Determine if this is an OAuth token or a bearer token
    let isOAuthToken = false;
    let isValidToken = false;

    if (token) {
      // Log token prefix for debugging (first 10 chars only)
      console.log('Token prefix:', token.substring(0, 10) + '...');

      // First check if it matches the ClickUp bearer token (for Cursor, Claude Code)
      if (clickupAuthToken && token === clickupAuthToken) {
        isValidToken = true;
        console.log('Bearer token validated (direct access)');
      } else {
        // Try validating as OAuth token (for Claude Desktop)
        try {
          await provider.verifyAccessToken(token);
          isOAuthToken = true;
          isValidToken = true;
          console.log('OAuth token validated');
        } catch (error) {
          console.log('Token validation failed:', (error as Error).message);
          res.status(401).json({ error: 'Invalid or expired token' });
          return;
        }
      }
    } else {
      // No token provided - reject with 401 and WWW-Authenticate header to trigger OAuth discovery
      console.log('No authentication token provided - sending 401 to trigger OAuth discovery');
      res.setHeader('WWW-Authenticate', `Bearer realm="${BASE_URL}", error="invalid_token", error_description="No authorization token provided"`);
      res.status(401).json({ error: 'Authentication required. Please use OAuth.' });
      return;
    }

    // Proxy the request to ClickUp MCP
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Accept': 'application/json, text/event-stream'
    };

    // MCP Session Management:
    // - First request (initialize) should NOT include session ID
    // - Server responds with Mcp-Session-Id header
    // - All subsequent requests must include that session ID

    // Check if this is an initialize request
    const isInitializeRequest = req.body?.method === 'initialize';

    let sessionId: string | undefined;

    if (isInitializeRequest) {
      // Don't send session ID for initialize requests
      console.log('Initialize request - not sending session ID');
    } else {
      console.log('Request method:', req.body?.method);
      // For non-initialize requests, use stored session ID or accept client's session ID
      const clientSessionId = req.headers['mcp-session-id'] as string;

      if (token && sessionStore.has(token)) {
        sessionId = sessionStore.get(token);
        console.log('Using stored session ID for token:', sessionId);
      } else if (clientSessionId) {
        sessionId = clientSessionId;
        console.log('Using client-provided session ID:', sessionId);
      } else {
        // No session ID available - this will likely fail but let server handle it
        console.log('WARNING: Non-initialize request without session ID');
        console.log('Session store has', sessionStore.size, 'entries');
        console.log('Token in store?', token ? sessionStore.has(token) : 'no token');
      }

      if (sessionId) {
        headers['Mcp-Session-Id'] = sessionId;
      }
    }

    // Add ClickUp MCP auth token - but only if we're using OAuth token
    // If bearer token was used, it's already the correct token for ClickUp
    if (isOAuthToken && clickupAuthToken) {
      headers['Authorization'] = `Bearer ${clickupAuthToken}`;
    } else if (token) {
      // Pass through the original bearer token
      headers['Authorization'] = `Bearer ${token}`;
    }

    const response = await fetch(`${CLICKUP_MCP_URL}/mcp`, {
      method: req.method,
      headers,
      body: req.method !== 'GET' && req.method !== 'HEAD' ? JSON.stringify(req.body) : undefined
    });

    // Check if server returned a session ID in response
    const responseSessionId = response.headers.get('mcp-session-id');

    if (responseSessionId) {
      console.log('Server returned session ID:', responseSessionId);

      // Store session ID for this token
      if (token) {
        sessionStore.set(token, responseSessionId);
        console.log('Stored session ID for token');
      }
    }

    // Check if response is SSE (text/event-stream) or JSON
    const contentType = response.headers.get('content-type') || '';
    console.log('Response content-type:', contentType, 'Status:', response.status);

    if (contentType.includes('text/event-stream')) {
      // Stream SSE response
      console.log('Streaming SSE response');
      res.setHeader('Content-Type', 'text/event-stream');
      res.setHeader('Cache-Control', 'no-cache');
      res.setHeader('Connection', 'keep-alive');

      // Copy headers from backend response (but not the ones we want to control)
      response.headers.forEach((value, key) => {
        const keyLower = key.toLowerCase();
        if (keyLower !== 'transfer-encoding' &&
            keyLower !== 'content-encoding' &&
            keyLower !== 'mcp-session-id') {
          res.setHeader(key, value);
        }
      });

      // IMPORTANT: Set session ID header AFTER copying other headers to ensure it's not overwritten
      if (responseSessionId) {
        res.setHeader('Mcp-Session-Id', responseSessionId);
        console.log('Set Mcp-Session-Id header in SSE response:', responseSessionId);
      }

      // Stream the response body
      if (response.body) {
        response.body.pipe(res);
      } else {
        res.end();
      }
    } else if (response.status === 202 || response.status === 204) {
      // Handle 202 Accepted or 204 No Content (notifications don't have response bodies)
      console.log('Notification accepted - no response body');

      // Set session ID header
      if (responseSessionId) {
        res.setHeader('Mcp-Session-Id', responseSessionId);
        console.log('Set Mcp-Session-Id header in notification response:', responseSessionId);
      }

      res.sendStatus(response.status);
    } else {
      // Handle JSON response
      console.log('Parsing JSON response');

      // Set session ID header for JSON responses too
      if (responseSessionId) {
        res.setHeader('Mcp-Session-Id', responseSessionId);
        console.log('Set Mcp-Session-Id header in JSON response:', responseSessionId);
      }

      const data = await response.json();
      res.status(response.status).json(data);
    }
  } catch (error) {
    console.error('Proxy error:', error);
    res.status(500).json({
      error: 'Internal proxy error',
      message: (error as Error).message
    });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`OAuth Proxy running on port ${PORT}`);
  console.log(`OAuth Mode: GitHub`);
  console.log(`OAuth endpoints:`);
  console.log(`  Metadata: ${BASE_URL}/.well-known/oauth-authorization-server`);
  console.log(`  Register: ${BASE_URL}/oauth/register`);
  console.log(`  Authorize: ${BASE_URL}/oauth/authorize`);
  console.log(`  Token: ${BASE_URL}/oauth/token`);
  console.log(`  Callback: ${BASE_URL}/oauth/callback`);
  console.log(`  MCP: ${BASE_URL}/mcp`);
});
