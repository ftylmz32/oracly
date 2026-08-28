import { generateKeyPair, exportJWK, SignJWT, createLocalJWKSet } from 'jose';
import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { JwksAuthenticationService } from '../src/auth/jwt-jwks.js';
import { authHeader, chatBody, testApp, testConfig } from './helpers.js';

const issuer = 'https://securetoken.google.com/example-project-id';
const audience = 'example-project-id';

async function firebaseVerifier() {
  const { publicKey, privateKey } = await generateKeyPair('RS256');
  const jwk = await exportJWK(publicKey);
  jwk.kid = 'firebase-test-kid';
  jwk.alg = 'RS256';
  return {
    privateKey,
    service: new JwksAuthenticationService(
      createLocalJWKSet({ keys: [jwk] }),
      { jwtIssuer: issuer, jwtAudience: audience },
    ),
  };
}

async function signFirebase(
  privateKey: CryptoKey,
  overrides: {
    sub?: string | null;
    iss?: string;
    aud?: string;
    exp?: number;
  } = {},
) {
  const jwt = new SignJWT({});
  jwt.setProtectedHeader({ alg: 'RS256', kid: 'firebase-test-kid' });
  jwt.setIssuer(overrides.iss ?? issuer);
  jwt.setAudience(overrides.aud ?? audience);
  if (overrides.exp != null) jwt.setExpirationTime(overrides.exp);
  else jwt.setExpirationTime('1h');
  if (overrides.sub !== null) {
    jwt.setSubject(overrides.sub ?? 'firebase-uid-1');
  }
  return jwt.sign(privateKey);
}

describe('Firebase JWT / JWKS', () => {
  it('accepts a valid Firebase-shaped RS256 token', async () => {
    const { privateKey, service } = await firebaseVerifier();
    const token = await signFirebase(privateKey);
    const result = await service.authenticate(`Bearer ${token}`);
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.identity.subject).toBe('firebase-uid-1');
      expect(result.identity.identityKey).toBe(
        identityKeyFromSubject('firebase-uid-1'),
      );
    }
  });

  it('rejects invalid signature, expiry, issuer, audience, and missing sub', async () => {
    const { privateKey, service } = await firebaseVerifier();
    const other = await generateKeyPair('RS256');
    expect(
      (await service.authenticate(`Bearer ${await signFirebase(other.privateKey)}`))
        .ok,
    ).toBe(false);
    expect(
      (
        await service.authenticate(
          `Bearer ${await signFirebase(privateKey, {
            exp: Math.floor(Date.now() / 1000) - 120,
          })}`,
        )
      ).ok,
    ).toBe(false);
    expect(
      (
        await service.authenticate(
          `Bearer ${await signFirebase(privateKey, {
            iss: 'https://securetoken.google.com/other-project',
          })}`,
        )
      ).ok,
    ).toBe(false);
    expect(
      (
        await service.authenticate(
          `Bearer ${await signFirebase(privateKey, { aud: 'other-project' })}`,
        )
      ).ok,
    ).toBe(false);
    expect(
      (
        await service.authenticate(
          `Bearer ${await signFirebase(privateKey, { sub: null })}`,
        )
      ).ok,
    ).toBe(false);
  });

  it('rejects malformed Bearer and OpenAI keys; body userId cannot override sub', async () => {
    const app = await testApp(
      testConfig({
        APP_ENV: 'production',
        FIREBASE_PROJECT_ID: 'example-project-id',
      }),
    );
    const missing = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json', authorization: 'Bearer' },
      payload: { ...chatBody, userId: 'spoof' },
    });
    expect(missing.statusCode).toBe(401);
    const openai = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader('sk-not-a-user-token'),
      payload: { ...chatBody, userId: 'spoof' },
    });
    expect(openai.statusCode).toBe(401);
    expect(openai.json().error.code).toBe('unauthorized');
    await app.close();
  });
});
