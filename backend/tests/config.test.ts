import { describe, expect, it } from 'vitest';
import { loadConfig } from '../src/config.js';

describe('config host binding', () => {
  it('defaults to loopback in development', () => {
    const cfg = loadConfig({ APP_ENV: 'development' });
    expect(cfg.host).toBe('127.0.0.1');
    expect(cfg.port).toBe(8787);
    expect(cfg.authMode).toBe('opaque');
  });

  it('allows explicit 0.0.0.0 for device/LAN testing', () => {
    const cfg = loadConfig({ APP_ENV: 'development', HOST: '0.0.0.0' });
    expect(cfg.host).toBe('0.0.0.0');
  });

  it('production defaults to 0.0.0.0 and uses platform PORT', () => {
    const cfg = loadConfig({ APP_ENV: 'production', PORT: '8080' });
    expect(cfg.host).toBe('0.0.0.0');
    expect(cfg.port).toBe(8080);
    expect(cfg.devAuthBypass).toBe(false);
    expect(cfg.authRequired).toBe(true);
    expect(cfg.authMode).toBe('fail_closed');
  });

  it('production honors explicit HOST override', () => {
    const cfg = loadConfig({ APP_ENV: 'production', HOST: '127.0.0.1' });
    expect(cfg.host).toBe('127.0.0.1');
  });

  it('production JWKS must be https', () => {
    const http = loadConfig({
      APP_ENV: 'production',
      AI_JWKS_URL: 'http://idp.example/.well-known/jwks.json',
    });
    expect(http.jwksUrl).toBeNull();
    expect(http.authMode).toBe('fail_closed');
    const https = loadConfig({
      APP_ENV: 'production',
      AI_JWKS_URL: 'https://idp.example/.well-known/jwks.json',
      AI_JWT_ISSUER: 'https://idp.example',
      AI_JWT_AUDIENCE: 'oracly-ai',
    });
    expect(https.authMode).toBe('jwks');
  });

  it('FIREBASE_PROJECT_ID fills JWKS issuer and audience placeholders', () => {
    const cfg = loadConfig({
      APP_ENV: 'production',
      FIREBASE_PROJECT_ID: 'example-project-id',
    });
    expect(cfg.authMode).toBe('jwks');
    expect(cfg.jwksUrl).toBe(
      'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
    );
    expect(cfg.jwtIssuer).toBe(
      'https://securetoken.google.com/example-project-id',
    );
    expect(cfg.jwtAudience).toBe('example-project-id');
  });

  it('oracly-7f613 maps to Google JWKS issuer and audience', () => {
    const cfg = loadConfig({
      APP_ENV: 'production',
      FIREBASE_PROJECT_ID: 'oracly-7f613',
    });
    expect(cfg.authMode).toBe('jwks');
    expect(cfg.jwtIssuer).toBe(
      'https://securetoken.google.com/oracly-7f613',
    );
    expect(cfg.jwtAudience).toBe('oracly-7f613');
  });

  it('staging ignores bypass like production', () => {
    const cfg = loadConfig({
      APP_ENV: 'staging',
      AI_DEV_AUTH_BYPASS: 'true',
    });
    expect(cfg.devAuthBypass).toBe(false);
    expect(cfg.authMode).toBe('fail_closed');
  });
});
