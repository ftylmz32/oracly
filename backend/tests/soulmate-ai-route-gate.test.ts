import { beforeEach, describe, expect, it } from 'vitest';
import { identityKeyFromOpaqueToken } from '../src/auth/identity.js';
import { resetSoulmateUniquenessIndex } from '../src/ai/soulmate-uniqueness-index.js';
import { denySoulmateWithoutPremium } from '../src/reading/soulmate-ai-route-gate.js';
import { InMemorySoulmateEntitlementGuard } from '../src/reading/soulmate-entitlement-guard.js';
import {
  authHeader,
  openaiImage,
  openaiText,
  soulmateBody,
  testApp,
  testConfig,
} from './helpers.js';

const token = 'user-access-token';

describe('soulmate route premium gate', () => {
  beforeEach(() => {
    resetSoulmateUniquenessIndex();
  });

  it('does not call the image provider when premium is absent', async () => {
    let images = 0;
    const imageFetch = openaiImage();
    const fetchImpl: typeof fetch = async (url, init) => {
      if (String(url).includes('/images/')) images += 1;
      return imageFetch(url, init);
    };
    const app = await testApp(testConfig(), fetchImpl, {
      soulmateEntitlement: new InMemorySoulmateEntitlementGuard(),
    });
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(token),
      payload: soulmateBody,
    });
    expect(res.statusCode).toBe(403);
    expect(res.json().error.code).toBe('forbidden');
    expect(images).toBe(0);
    await app.close();
  });

  it('does not call chat when interpretation lacks premium', async () => {
    let chats = 0;
    const textFetch = openaiText('{"personality":"x","meeting":"y","feeling":"z"}');
    const fetchImpl: typeof fetch = async (url, init) => {
      if (String(url).includes('/chat/completions')) chats += 1;
      return textFetch(url, init);
    };
    const app = await testApp(testConfig(), fetchImpl, {
      soulmateEntitlement: new InMemorySoulmateEntitlementGuard(),
    });
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(token),
      payload: {
        operation: 'soulmate_interpretation',
        payload: { name: 'Ayse', birthDate: '1994-03-12', language: 'tr' },
      },
    });
    expect(res.statusCode).toBe(403);
    expect(chats).toBe(0);
    await app.close();
  });

  it('still generates one image for an active premium identity', async () => {
    const guard = new InMemorySoulmateEntitlementGuard();
    guard.grant(identityKeyFromOpaqueToken(token));
    let images = 0;
    const imageFetch = openaiImage();
    const fetchImpl: typeof fetch = async (url, init) => {
      if (String(url).includes('/images/')) images += 1;
      return imageFetch(url, init);
    };
    const app = await testApp(testConfig(), fetchImpl, {
      soulmateEntitlement: guard,
    });
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(token),
      payload: soulmateBody,
    });
    expect(res.statusCode).toBe(200);
    expect(images).toBe(1);
    await app.close();
  });

  it('fails closed in a locked env when no guard is wired', async () => {
    const denied = await denySoulmateWithoutPremium({
      operation: 'soulmate_draw',
      identity: 'tok:abc',
      config: { ...testConfig(), appEnv: 'production' },
      guard: undefined,
    });
    expect(denied?.status).toBe(503);
    expect(denied?.body.error.code).toBe('no_configuration');
  });

  it('leaves chat outside the premium gate', async () => {
    const denied = await denySoulmateWithoutPremium({
      operation: 'chat',
      identity: 'tok:abc',
      config: { ...testConfig(), appEnv: 'production' },
      guard: new InMemorySoulmateEntitlementGuard(),
    });
    expect(denied).toBeNull();
  });
});
