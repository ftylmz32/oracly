import { generateKeyPair, exportJWK, SignJWT, createLocalJWKSet } from 'jose';
import { describe, expect, it } from 'vitest';
import { JwksAuthenticationService } from '../src/auth/jwt-jwks.js';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import {
  appCheckHeader,
  authHeader,
  chatBody,
  signHs256,
  StaticAppCheckVerifier,
  testApp,
  testConfig,
} from './helpers.js';

describe('auth', () => {
  it('rejects missing Authorization when auth is required', async () => {
    const app = await testApp(testConfig());
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: chatBody,
    });
    expect(res.statusCode).toBe(401);
    expect(res.json()).toEqual({
      success: false,
      error: { code: 'unauthorized' },
    });
    await app.close();
  });

  it('rejects malformed Authorization', async () => {
    const app = await testApp(testConfig());
    for (const authorization of ['Bearer', 'Bearer ', 'Token abc', 'abc']) {
      const res = await app.inject({
        method: 'POST',
        url: '/v1/ai/complete',
        headers: { authorization, 'content-type': 'application/json' },
        payload: chatBody,
      });
      expect(res.statusCode).toBe(401);
      expect(res.json().error.code).toBe('unauthorized');
    }
    await app.close();
  });

  it('rejects OpenAI keys used as bearer tokens', async () => {
    const app = await testApp(testConfig());
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader('sk-client-must-not-work'),
      payload: chatBody,
    });
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('unauthorized');
    await app.close();
  });

  it('allows documented development auth bypass only outside production', async () => {
    const app = await testApp(
      testConfig({ AI_DEV_AUTH_BYPASS: 'true', AI_AUTH_REQUIRED: 'true' }),
    );
    expect(testConfig({ AI_DEV_AUTH_BYPASS: 'true' }).authMode).toBe('bypass');
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: chatBody,
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().success).toBe(true);
    await app.close();
  });

  it('ignores development bypass in production and fail-closes without verifier', async () => {
    const config = testConfig({
      APP_ENV: 'production',
      AI_DEV_AUTH_BYPASS: 'true',
      AI_AUTH_REQUIRED: 'false',
    });
    expect(config.authRequired).toBe(true);
    expect(config.devAuthBypass).toBe(false);
    expect(config.authMode).toBe('fail_closed');
    const app = await testApp(config);
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader('user-access-token'),
      payload: chatBody,
    });
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('unauthorized');
    expect(res.body).not.toContain('JWT');
    expect(res.body).not.toContain('signature');
    await app.close();
  });

  it('production requires real JWT when HS256 is configured', async () => {
    const secret = 'unit-test-jwt-secret';
    const config = testConfig({
      APP_ENV: 'production',
      AI_JWT_SECRET: secret,
      AI_JWT_ISSUER: 'https://issuer.example',
      AI_JWT_AUDIENCE: 'oracly-ai',
    });
    expect(config.authMode).toBe('hs256');
    const app = await testApp(config, undefined, {
      appCheck: new StaticAppCheckVerifier('good-token'),
    });
    const ok = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: {
        ...authHeader(
          signHs256(secret, {
            iss: 'https://issuer.example',
            aud: 'oracly-ai',
          }),
        ),
        ...appCheckHeader('good-token'),
      },
      payload: chatBody,
    });
    expect(ok.statusCode).toBe(200);
    expect(ok.json().success).toBe(true);

    const expired = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(
        signHs256(secret, {
          iss: 'https://issuer.example',
          aud: 'oracly-ai',
          exp: Math.floor(Date.now() / 1000) - 60,
        }),
      ),
      payload: chatBody,
    });
    expect(expired.statusCode).toBe(401);

    const wrongIss = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(
        signHs256(secret, { iss: 'https://other.example', aud: 'oracly-ai' }),
      ),
      payload: chatBody,
    });
    expect(wrongIss.statusCode).toBe(401);

    const wrongAud = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(
        signHs256(secret, { iss: 'https://issuer.example', aud: 'other-app' }),
      ),
      payload: chatBody,
    });
    expect(wrongAud.statusCode).toBe(401);

    const badSig = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(
        signHs256('wrong-secret', {
          iss: 'https://issuer.example',
          aud: 'oracly-ai',
        }),
      ),
      payload: chatBody,
    });
    expect(badSig.statusCode).toBe(401);
    expect(JSON.stringify(badSig.json())).not.toContain('issuer');
    await app.close();
  });

  it('userId in the request body cannot bypass auth', async () => {
    const app = await testApp(
      testConfig({ APP_ENV: 'production', AI_JWT_SECRET: 'unit-test-jwt-secret' }),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: { ...chatBody, userId: 'admin', user_id: 'admin', sub: 'admin' },
    });
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('unauthorized');
    await app.close();
  });

  it('rate limiting uses verified JWT subject, not body userId', async () => {
    const secret = 'unit-test-jwt-secret';
    const app = await testApp(
      testConfig({
        AI_JWT_SECRET: secret,
        AI_RATE_LIMIT_MAX: '2',
        AI_RATE_LIMIT_WINDOW_MS: '60000',
      }),
    );
    const tokenA = signHs256(secret, { sub: 'user-a' });
    const tokenA2 = signHs256(secret, { sub: 'user-a', jti: 'second' });
    const tokenB = signHs256(secret, { sub: 'user-b' });
    const first = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(tokenA),
      payload: {
        ...chatBody,
        userId: 'spoof-b',
        payload: { ...chatBody.payload, userMessage: 'Ilk.' },
      },
    });
    const second = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(tokenA2),
      payload: {
        ...chatBody,
        userId: 'spoof-b',
        payload: { ...chatBody.payload, userMessage: 'Ikinci.' },
      },
    });
    const third = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(tokenA),
      payload: {
        ...chatBody,
        payload: { ...chatBody.payload, userMessage: 'Ucuncu.' },
      },
    });
    const other = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(tokenB),
      payload: {
        ...chatBody,
        payload: { ...chatBody.payload, userMessage: 'Diger kullanici.' },
      },
    });
    expect(first.json().success).toBe(true);
    expect(second.json().success).toBe(true);
    expect(third.statusCode).toBe(429);
    expect(other.json().success).toBe(true);
    expect(identityKeyFromSubject('user-a')).not.toBe(
      identityKeyFromSubject('user-b'),
    );
    await app.close();
  });

  it('JWKS RS256 verifies subject and rejects bad signatures', async () => {
    const { publicKey, privateKey } = await generateKeyPair('RS256');
    const jwk = await exportJWK(publicKey);
    jwk.kid = 'test-kid';
    jwk.alg = 'RS256';
    const service = new JwksAuthenticationService(
      createLocalJWKSet({ keys: [jwk] }),
      { jwtIssuer: 'https://idp.example', jwtAudience: 'oracly-ai' },
    );
    const token = await new SignJWT({ sub: 'jwks-user' })
      .setProtectedHeader({ alg: 'RS256', kid: 'test-kid' })
      .setIssuer('https://idp.example')
      .setAudience('oracly-ai')
      .setExpirationTime('1h')
      .sign(privateKey);
    const ok = await service.authenticate(`Bearer ${token}`);
    expect(ok.ok).toBe(true);
    if (ok.ok) {
      expect(ok.identity.subject).toBe('jwks-user');
      expect(ok.identity.identityKey.startsWith('sub:')).toBe(true);
    }
    const other = await generateKeyPair('RS256');
    const bad = await new SignJWT({ sub: 'jwks-user' })
      .setProtectedHeader({ alg: 'RS256', kid: 'test-kid' })
      .setIssuer('https://idp.example')
      .setAudience('oracly-ai')
      .setExpirationTime('1h')
      .sign(other.privateKey);
    const rejected = await service.authenticate(`Bearer ${bad}`);
    expect(rejected.ok).toBe(false);
  });
});
