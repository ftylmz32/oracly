import { createRemoteJWKSet } from 'jose';
import { describe, expect, it } from 'vitest';
import {
  BypassAppCheckVerifier,
  FailClosedAppCheckVerifier,
  FirebaseAppCheckVerifier,
  StaticAppCheckVerifier,
} from '../src/auth/app-check.js';
import { loadConfig } from '../src/config.js';
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
  iss: 'https://securetoken.google.com/oracly-7f613',
  aud: 'oracly-7f613',
} as const;

/** Production-locked HS256 — avoids live JWKS so App Check gate is reachable. */
function prodConfig(extra: Record<string, string> = {}) {
  return testConfig({
    APP_ENV: 'production',
    AI_JWT_SECRET: JWT.secret,
    AI_JWT_ISSUER: JWT.iss,
    AI_JWT_AUDIENCE: JWT.aud,
    AI_JWKS_URL: '',
    FIREBASE_PROJECT_ID: '',
    ...extra,
  });
}

function authOk(claims: Record<string, unknown> = {}) {
  return authHeader(
    signHs256(JWT.secret, {
      iss: JWT.iss,
      aud: JWT.aud,
      ...claims,
    }),
  );
}

describe('E2 Auth + App Check fail-closed', () => {
  it('accepts valid ID token + valid App Check together', async () => {
    const app = await testApp(prodConfig(), openaiText('Sakin.'), {
      appCheck: new StaticAppCheckVerifier('good-token'),
    });
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authOk(), ...appCheckHeader('good-token') },
      payload: chatBody,
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().success).toBe(true);
    await app.close();
  });

  it('rejects missing ID token', async () => {
    const app = await testApp(prodConfig(), openaiText('ok'), {
      appCheck: new StaticAppCheckVerifier('good-token'),
    });
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

  it('rejects expired ID token', async () => {
    const app = await testApp(prodConfig(), openaiText('ok'), {
      appCheck: new StaticAppCheckVerifier('good-token'),
    });
    const expired = authOk({ exp: Math.floor(Date.now() / 1000) - 120 });
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...expired, ...appCheckHeader('good-token') },
      payload: chatBody,
    });
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('unauthorized');
    await app.close();
  });

  it('rejects wrong audience', async () => {
    const app = await testApp(prodConfig(), openaiText('ok'), {
      appCheck: new StaticAppCheckVerifier('good-token'),
    });
    const wrongAud = authOk({ aud: 'other-project' });
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...wrongAud, ...appCheckHeader('good-token') },
      payload: chatBody,
    });
    expect(res.statusCode).toBe(401);
    await app.close();
  });

  it('rejects missing and invalid App Check', async () => {
    const app = await testApp(prodConfig(), openaiText('ok'), {
      appCheck: new StaticAppCheckVerifier('good-token'),
    });
    const missing = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authOk(),
      payload: chatBody,
    });
    expect(missing.json().error.code).toBe('app_check_required');
    const bad = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authOk(), ...appCheckHeader('expired-or-bad') },
      payload: chatBody,
    });
    expect(bad.json().error.code).toBe('app_check_required');
    await app.close();
  });

  it('development bypass cannot activate in production', () => {
    const cfg = loadConfig({
      APP_ENV: 'production',
      AI_DEV_AUTH_BYPASS: 'true',
      AI_APP_CHECK_BYPASS: 'true',
      FIREBASE_PROJECT_ID: 'oracly-7f613',
      OPENAI_API_KEY: 'sk-test',
    });
    expect(cfg.devAuthBypass).toBe(false);
    expect(cfg.appCheckBypass).toBe(false);
    expect(cfg.appCheckRequired).toBe(true);
    expect(cfg.authMode).not.toBe('bypass');
  });

  it('fail-closed App Check when project missing', async () => {
    const verifier = new FailClosedAppCheckVerifier();
    expect(verifier.mode).toBe('fail_closed');
    expect((await verifier.verify('anything')).ok).toBe(false);
    const bypass = new BypassAppCheckVerifier();
    expect(bypass.mode).toBe('bypass');
  });

  it('App Check app-id allowlist rejects garbage tokens', async () => {
    const verifier = new FirebaseAppCheckVerifier(
      createRemoteJWKSet(
        new URL('https://firebaseappcheck.googleapis.com/v1/jwks'),
      ),
      'oracly-7f613',
      '1234567890',
      ['1:123:android:allowed'],
    );
    expect((await verifier.verify('')).ok).toBe(false);
    expect((await verifier.verify('not.a.jwt')).ok).toBe(false);
  });

  it('loads FIREBASE_APP_CHECK_APP_IDS into config', () => {
    const cfg = loadConfig({
      APP_ENV: 'production',
      FIREBASE_PROJECT_ID: 'oracly-7f613',
      FIREBASE_APP_CHECK_APP_IDS: '1:1:android:abc,1:1:ios:def',
      OPENAI_API_KEY: 'sk-test',
    });
    expect(cfg.firebaseAppCheckAppIds).toEqual([
      '1:1:android:abc',
      '1:1:ios:def',
    ]);
  });
});
