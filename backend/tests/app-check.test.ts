import { describe, expect, it } from 'vitest';
import {
  BypassAppCheckVerifier,
  FailClosedAppCheckVerifier,
  StaticAppCheckVerifier,
} from '../src/auth/app-check.js';
import {
  appCheckHeader,
  authHeader,
  chatBody,
  openaiText,
  signHs256,
  testApp,
  testConfig,
} from './helpers.js';

const JWT = {
  secret: 'unit-test-jwt-secret',
  iss: 'https://issuer.example',
  aud: 'oracly-ai',
} as const;

function prodHs256Config() {
  return testConfig({
    APP_ENV: 'production',
    AI_JWT_SECRET: JWT.secret,
    AI_JWT_ISSUER: JWT.iss,
    AI_JWT_AUDIENCE: JWT.aud,
  });
}

function authOk() {
  return authHeader(
    signHs256(JWT.secret, {
      iss: JWT.iss,
      aud: JWT.aud,
    }),
  );
}

describe('App Check gate', () => {
  it('rejects missing App Check when required', async () => {
    const app = await testApp(
      prodHs256Config(),
      openaiText('ok'),
      { appCheck: new StaticAppCheckVerifier('good-token') },
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authOk(),
      payload: chatBody,
    });
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('app_check_required');
    expect(JSON.stringify(res.json()).toLowerCase()).not.toContain('appcheck');
    await app.close();
  });

  it('rejects invalid App Check when required', async () => {
    const app = await testApp(
      prodHs256Config(),
      openaiText('ok'),
      { appCheck: new StaticAppCheckVerifier('good-token') },
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: {
        ...authOk(),
        ...appCheckHeader('bad-token'),
      },
      payload: chatBody,
    });
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('app_check_required');
    await app.close();
  });

  it('accepts verified App Check after Firebase Auth', async () => {
    const app = await testApp(
      prodHs256Config(),
      openaiText('Sakin bir yanit.'),
      { appCheck: new StaticAppCheckVerifier('good-token') },
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: {
        ...authOk(),
        ...appCheckHeader('good-token'),
      },
      payload: chatBody,
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().success).toBe(true);
    await app.close();
  });

  it('dev/test bypass only when explicitly configured', async () => {
    const bypassCfg = testConfig({
      AI_APP_CHECK_REQUIRED: 'true',
      AI_APP_CHECK_BYPASS: 'true',
    });
    expect(bypassCfg.appCheckRequired).toBe(false);
    expect(bypassCfg.appCheckBypass).toBe(true);

    const app = await testApp(
      bypassCfg,
      openaiText('Tamam.'),
      { appCheck: new BypassAppCheckVerifier() },
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: chatBody,
    });
    expect(res.json().success).toBe(true);
    await app.close();

    const locked = testConfig({
      APP_ENV: 'production',
      FIREBASE_PROJECT_ID: 'oracly-test',
      AI_APP_CHECK_BYPASS: 'true',
    });
    expect(locked.appCheckRequired).toBe(true);
    expect(locked.appCheckBypass).toBe(false);
  });

  it('fail-closed App Check rejects AI when verifier unavailable', async () => {
    const app = await testApp(
      prodHs256Config(),
      openaiText('ok'),
      { appCheck: new FailClosedAppCheckVerifier() },
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: {
        ...authOk(),
        ...appCheckHeader('any'),
      },
      payload: chatBody,
    });
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('app_check_required');
    await app.close();
  });

  it('health and readiness remain usable without App Check tokens', async () => {
    const app = await testApp(
      prodHs256Config(),
      openaiText('ok'),
      { appCheck: new StaticAppCheckVerifier('good-token') },
    );
    const health = await app.inject({ method: 'GET', url: '/health' });
    const ready = await app.inject({ method: 'GET', url: '/ready' });
    expect(health.statusCode).toBe(200);
    expect(health.json()).toEqual({ status: 'ok' });
    expect(ready.statusCode).toBe(200);
    expect(ready.json().status).toBe('ready');
    expect(ready.json().capabilities.alive).toBe(true);
    await app.close();
  });

  it('Firebase Auth still required when App Check is present', async () => {
    const app = await testApp(
      prodHs256Config(),
      openaiText('ok'),
      { appCheck: new StaticAppCheckVerifier('good-token') },
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: {
        'content-type': 'application/json',
        ...appCheckHeader('good-token'),
      },
      payload: chatBody,
    });
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('unauthorized');
    await app.close();
  });
});

