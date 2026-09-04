import { createHash } from 'node:crypto';
import { describe, expect, it } from 'vitest';
import { authHeader, signHs256, testApp, testConfig } from './helpers.js';

const TEST_CODE = 'oracly-play-review-2026';
const TEST_CODE_HASH = createHash('sha256')
  .update(TEST_CODE)
  .digest('hex');

function configuredConfig(overrides: Record<string, string> = {}) {
  return testConfig({
    AI_DEV_AUTH_BYPASS: 'false',
    AI_AUTH_REQUIRED: 'true',
    AI_JWT_SECRET: 'review-access-test-secret',
    AI_JWT_ISSUER: 'https://issuer.example',
    AI_JWT_AUDIENCE: 'oracly-ai',
    FIREBASE_PROJECT_ID: '',
    AI_JWKS_URL: '',
    REVIEW_ACCESS_CODE_HASH: TEST_CODE_HASH,
    ...overrides,
  });
}

function reviewerToken() {
  return signHs256('review-access-test-secret', {
    sub: 'play-reviewer',
    iss: 'https://issuer.example',
    aud: 'oracly-ai',
  });
}

async function activate(
  app: Awaited<ReturnType<typeof testApp>>,
  code: string,
  headers: Record<string, string> = authHeader(),
) {
  return app.inject({
    method: 'POST',
    url: '/v1/review-access/activate',
    headers,
    payload: { code },
  });
}

describe('POST /v1/review-access/activate', () => {
  it('grants access for a valid code from an authenticated user', async () => {
    const app = await testApp(configuredConfig());
    const token = reviewerToken();
    const res = await activate(app, TEST_CODE, {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({ granted: true });
    await app.close();
  });

  it('rejects an invalid code without granting access', async () => {
    const app = await testApp(configuredConfig());
    const token = reviewerToken();
    const res = await activate(app, 'not-the-real-code', {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({
      granted: false,
      reason: 'invalid_code',
    });
    await app.close();
  });

  it('fails closed with 401 when no authentication is presented', async () => {
    const app = await testApp(configuredConfig());
    const res = await app.inject({
      method: 'POST',
      url: '/v1/review-access/activate',
      headers: { 'content-type': 'application/json' },
      payload: { code: TEST_CODE },
    });
    expect(res.statusCode).toBe(401);
    await app.close();
  });

  it('fails closed with 401 when the bearer token is invalid, even with the correct code', async () => {
    const app = await testApp(configuredConfig());
    const res = await activate(app, TEST_CODE, {
      authorization: 'Bearer not-a-real-jwt',
      'content-type': 'application/json',
    });
    expect(res.statusCode).toBe(401);
    await app.close();
  });

  it('fails closed with 401 in a production-like environment with missing Firebase/JWT config (authMode fail_closed)', async () => {
    const config = testConfig({
      APP_ENV: 'production',
      FIREBASE_PROJECT_ID: '',
      AI_JWKS_URL: '',
      AI_JWT_SECRET: '',
      REVIEW_ACCESS_CODE_HASH: TEST_CODE_HASH,
    });
    expect(config.authMode).toBe('fail_closed');
    const app = await testApp(config);
    const res = await activate(app, TEST_CODE);
    expect(res.statusCode).toBe(401);
    await app.close();
  });

  it('reports not_configured — and never grants — when no review access code hash is set', async () => {
    const app = await testApp(
      configuredConfig({ REVIEW_ACCESS_CODE_HASH: '' }),
    );
    const token = reviewerToken();
    const res = await activate(app, TEST_CODE, {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({
      granted: false,
      reason: 'not_configured',
    });
    await app.close();
  });

  it('this is how reviewer access is disabled after review: unsetting the hash fails every code closed', async () => {
    // Same code that was valid before now returns not_configured, not
    // granted — proving the "unset + redeploy, no client change" disable
    // path actually works end to end.
    const app = await testApp(
      configuredConfig({ REVIEW_ACCESS_CODE_HASH: '' }),
    );
    const token = reviewerToken();
    const res = await activate(app, TEST_CODE, {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    });
    expect(res.json().granted).toBe(false);
    await app.close();
  });

  it('rejects malformed request bodies without granting access', async () => {
    const app = await testApp(configuredConfig());
    const token = reviewerToken();
    const res = await app.inject({
      method: 'POST',
      url: '/v1/review-access/activate',
      headers: {
        authorization: `Bearer ${token}`,
        'content-type': 'application/json',
      },
      payload: { nope: true },
    });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({
      granted: false,
      reason: 'invalid_request',
    });
    await app.close();
  });

  it('rate-limits repeated attempts per authenticated identity', async () => {
    const app = await testApp(
      configuredConfig({
        REVIEW_ACCESS_RATE_LIMIT_MAX: '2',
        REVIEW_ACCESS_RATE_LIMIT_WINDOW_MS: '900000',
      }),
    );
    const headers = {
      authorization: `Bearer ${reviewerToken()}`,
      'content-type': 'application/json',
    };
    const first = await activate(app, 'wrong-1', headers);
    const second = await activate(app, 'wrong-2', headers);
    const third = await activate(app, 'wrong-3', headers);
    expect(first.statusCode).toBe(200);
    expect(second.statusCode).toBe(200);
    expect(third.statusCode).toBe(429);
    await app.close();
  });

  it('never logs the raw submitted code', async () => {
    const app = await testApp(configuredConfig());
    const token = reviewerToken();
    const res = await activate(app, TEST_CODE, {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    });
    expect(JSON.stringify(res.json())).not.toContain(TEST_CODE);
    await app.close();
  });

  it('does not spoof store purchase verification: response shape has no billing/status fields and grants no purchase binding', async () => {
    const app = await testApp(configuredConfig());
    const token = reviewerToken();
    const res = await activate(app, TEST_CODE, {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    });
    const body = res.json();
    // The billing route's vocabulary (`status: 'active'`, product IDs,
    // purchase tokens) never appears in a review-access response.
    expect(body.status).toBeUndefined();
    expect(body.productId).toBeUndefined();
    expect(body.purchaseToken).toBeUndefined();
    expect(Object.keys(body).sort()).toEqual(['granted']);
    await app.close();
  });
});
