import { randomUUID } from 'node:crypto';
import type { OAuthServerProvider } from '@modelcontextprotocol/sdk/server/auth/provider.js';
import type { OAuthClientInformationFull, OAuthTokens } from '@modelcontextprotocol/sdk/shared/auth.js';
import type { AuthInfo } from '@modelcontextprotocol/sdk/server/auth/types.js';
import type { OAuthRegisteredClientsStore } from '@modelcontextprotocol/sdk/server/auth/clients.js';
import { Response } from 'express';
import { OAuthStorage } from './oauth-storage.js';

export class PersistentClientsStore implements OAuthRegisteredClientsStore {
  constructor(private storage: OAuthStorage) {}

  async getClient(clientId: string): Promise<OAuthClientInformationFull | undefined> {
    return this.storage.getClient(clientId);
  }

  async registerClient(clientMetadata: OAuthClientInformationFull): Promise<OAuthClientInformationFull> {
    return this.storage.registerClient(clientMetadata);
  }
}

export class ClickUpMcpOAuthProvider implements OAuthServerProvider {
  private storage: OAuthStorage;
  private _clientsStore: PersistentClientsStore;

  constructor(dbPath?: string) {
    this.storage = new OAuthStorage(dbPath);
    this._clientsStore = new PersistentClientsStore(this.storage);

    // Cleanup expired tokens every hour
    setInterval(() => {
      const deletedTokens = this.storage.cleanupExpiredTokens();
      const deletedCodes = this.storage.cleanupExpiredCodes();
      if (deletedTokens > 0 || deletedCodes > 0) {
        console.log('OAuth cleanup:', { deletedTokens, deletedCodes });
      }
    }, 3600000);
  }

  get clientsStore(): OAuthRegisteredClientsStore {
    return this._clientsStore;
  }

  async authorize(
    client: OAuthClientInformationFull,
    params: {
      redirectUri: string;
      scopes?: string[];
      resource?: URL;
      state?: string;
      codeChallenge: string;
      codeChallengeMethod?: string;
    },
    res: Response
  ): Promise<void> {
    const code = randomUUID();
    const searchParams = new URLSearchParams({ code });

    if (params.state) {
      searchParams.set('state', params.state);
    }

    // Save code to storage
    this.storage.saveCode(code, {
      clientId: client.client_id,
      redirectUri: params.redirectUri,
      scopes: params.scopes?.join(' '),
      resource: params.resource?.toString(),
      state: params.state,
      codeChallenge: params.codeChallenge,
      codeChallengeMethod: params.codeChallengeMethod,
      expiresAt: Date.now() + 600000 // 10 minutes
    });

    if (!client.redirect_uris.includes(params.redirectUri)) {
      throw new Error('Unregistered redirect_uri');
    }

    const targetUrl = new URL(params.redirectUri);
    targetUrl.search = searchParams.toString();
    res.redirect(targetUrl.toString());
  }

  async challengeForAuthorizationCode(
    client: OAuthClientInformationFull,
    authorizationCode: string
  ): Promise<string> {
    const codeData = this.storage.getCode(authorizationCode);
    if (!codeData) {
      throw new Error('Invalid authorization code');
    }
    return codeData.codeChallenge;
  }

  async exchangeAuthorizationCode(
    client: OAuthClientInformationFull,
    authorizationCode: string,
    _codeVerifier?: string,
    _redirectUri?: string,
    _resource?: URL
  ): Promise<AuthInfo> {
    const codeData = this.storage.getCode(authorizationCode);
    if (!codeData) {
      throw new Error('Invalid authorization code');
    }

    if (codeData.clientId !== client.client_id) {
      throw new Error('Authorization code issued to different client');
    }

    // Delete the code (one-time use)
    this.storage.deleteCode(authorizationCode);

    // Generate access token
    const accessToken = randomUUID();
    const refreshToken = randomUUID();

    this.storage.saveToken({
      accessToken,
      tokenType: 'Bearer',
      expiresIn: 3600, // 1 hour
      refreshToken,
      scope: codeData.scopes,
      resource: codeData.resource,
      createdAt: Date.now()
    });

    return {
      tokens: {
        access_token: accessToken,
        token_type: 'Bearer',
        expires_in: 3600,
        refresh_token: refreshToken,
        scope: codeData.scopes
      },
      scopes: codeData.scopes?.split(' ')
    };
  }

  async validateAccessToken(token: string): Promise<AuthInfo> {
    const tokenData = this.storage.getToken(token);
    if (!tokenData) {
      throw new Error('Invalid or expired access token');
    }

    return {
      tokens: {
        access_token: tokenData.accessToken,
        token_type: tokenData.tokenType,
        expires_in: tokenData.expiresIn,
        refresh_token: tokenData.refreshToken,
        scope: tokenData.scope
      },
      scopes: tokenData.scope?.split(' ')
    };
  }

  async revokeToken(token: string): Promise<void> {
    // In a real implementation, we would delete the token from storage
    console.log('Token revoked:', token);
  }
}
