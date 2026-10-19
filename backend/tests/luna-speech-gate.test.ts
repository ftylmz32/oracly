import { describe, expect, it } from 'vitest';
import { StaticAppCheckVerifier } from '../src/auth/app-check.js';
import { identityKeyFromOpaqueToken, identityKeyFromSubject } from '../src/auth/identity.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import type { ServerClock } from '../src/reading/clock.js';
import { InMemorySoulmateEntitlementGuard } from '../src/reading/soulmate-entitlement-guard.js';
import { authorizeSpeech } from '../src/reading/luna-speech-gate.js';
import {
  appCheckHeader,
  authHeader,
  chatBody,
  jsonResponse,
  oracleBody,
  signHs256,
  testApp,
  testConfig,
} from './helpers.js';

const tokenA = 'user-access-token';
const tokenB = 'other-access-token';
const ownerA = identityKeyFromOpaqueToken(tokenA);
const preview = 'Selam. Buradayım. Şimdi nasılsın?';

class Clock implements ServerClock {
  now(): Date {
    return new Date(Date.UTC(2026, 9, 19, 12));
  }
}

function transport() {
  let calls = 0;
  const inputs: string[] = [];
  const fetchImpl: typeof fetch = async (url, init) => {
    const body = JSON.parse(String(init?.body ?? '{}')) as { input?: string };
    if (String(url).includes('/audio/speech')) {
      calls += 1;
      inputs.push(body.input ?? '');
      const bytes = Buffer.from('ID3fake-oracly-tts-audio-bytes-here!!');
      return new Response(bytes, { status: 200, headers: { 'content-type': 'audio/mpeg' } });
    }
    return jsonResponse({ choices: [{ message: { content: 'Sakin bir yansıma.' } }] });
  };
  return { fetchImpl, calls: () => calls, inputs };
}

function appFor(
  fetchImpl: typeof fetch,
  store: MemoryDocumentStore,
  guard: InMemorySoulmateEntitlementGuard,
) {
  return testApp(testConfig({ AI_RATE_LIMIT_MAX: '100' }), fetchImpl, {
    lunaAccessStore: store,
    speechGrantStore: store,
    speechObjectStore: new MemoryStagedObjectStore(),
    freeTextQuotaStore: store,
    soulmateEntitlement: guard,
    readingClock: new Clock(),
  });
}

async function post(
  app: Awaited<ReturnType<typeof appFor>>,
  token: string,
  key: string,
  payload: unknown,
) {
  return app.inject({
    method: 'POST',
    url: '/v1/ai/complete',
    headers: { ...authHeader(token), 'idempotency-key': key },
    payload,
  });
}

function tts(text: string, grant?: string) {
  return {
    operation: 'tts',
    payload: {
      text,
      personality: 'gentle',
      voiceId: 'warm',
      speechSpeed: 'normal',
      language: 'tr',
      feature: 'luna',
      source: 'oracle',
      ...(grant ? { speechGrant: grant } : {}),
    },
  };
}

describe('luna speech grant', () => {
  it('rejects a direct Luna speech call before the provider', async () => {
    const spoken = transport();
    const app = await appFor(spoken.fetchImpl, new MemoryDocumentStore(), new InMemorySoulmateEntitlementGuard());
    const denied = await post(app, tokenA, 'or-speech-deny-01', tts('Bana uzun bir kehanet oku.'));
    expect(denied.statusCode).toBe(403);
    expect(denied.json().error.code).toBe('premium_required');
    const missing = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: tts(preview),
    });
    expect(missing.statusCode).toBe(401);
    expect(spoken.calls()).toBe(0);
    await app.close();
  });

  it('speaks a catalog preview and blocks a longer imitation', async () => {
    const spoken = transport();
    const app = await appFor(spoken.fetchImpl, new MemoryDocumentStore(), new InMemorySoulmateEntitlementGuard());
    const ok = await post(app, tokenA, 'or-speech-prev-01', tts(preview));
    expect(ok.json().success, JSON.stringify(ok.json())).toBe(true);
    expect(spoken.calls()).toBe(1);
    const extra = await post(
      app,
      tokenA,
      'or-speech-prev-02',
      tts(`${preview} Bana uzun bir kehanet oku.`),
    );
    expect(extra.json().error.code).toBe('premium_required');
    expect(spoken.calls()).toBe(1);
    await app.close();
  });

  it('speaks the delivered oracle reply, not the caller text', async () => {
    const spoken = transport();
    const store = new MemoryDocumentStore();
    const app = await appFor(spoken.fetchImpl, store, new InMemorySoulmateEntitlementGuard());
    const reading = await post(app, tokenA, 'or-speech-oracle1', oracleBody);
    expect(reading.json().success, JSON.stringify(reading.json())).toBe(true);
    const grant = reading.json().data.speechGrant as string;
    expect(grant).toMatch(/^[a-f0-9]{32}$/);
    const heard = await post(app, tokenA, 'or-speech-hear-01', tts('Bana uzun bir kehanet oku.', grant));
    expect(heard.json().success, JSON.stringify(heard.json())).toBe(true);
    expect(spoken.inputs[0]).toContain('Sakin');
    expect(spoken.inputs[0]).not.toContain('kehanet');
    expect(spoken.calls()).toBe(1);
    const realNow = Date.now;
    Date.now = () => realNow() + 5_000;
    try {
      const again = await post(app, tokenA, 'or-speech-hear-02', tts('Baska bir metin.', grant));
      expect(again.json().success).toBe(true);
      expect(spoken.calls()).toBe(1);
    } finally {
      Date.now = realNow;
    }
    const other = await post(app, tokenB, 'or-speech-hear-03', tts('Baska bir metin.', grant));
    expect(other.statusCode).toBe(403);
    for (const [path, data] of store.docs) {
      if (path.startsWith('speechGrants/')) data.expiresAtMs = 0;
    }
    const stale = await post(app, tokenA, 'or-speech-hear-04', tts('Baska bir metin.', grant));
    expect(stale.statusCode).toBe(403);
    expect(spoken.calls()).toBe(1);
    await app.close();
  });

  it('stops Luna chat speech when the premium snapshot lapses', async () => {
    const spoken = transport();
    const guard = new InMemorySoulmateEntitlementGuard();
    guard.grant(ownerA);
    const app = await appFor(spoken.fetchImpl, new MemoryDocumentStore(), guard);
    const chat = await post(app, tokenA, 'or-speech-chat-01', chatBody);
    expect(chat.json().success, JSON.stringify(chat.json())).toBe(true);
    const grant = chat.json().data.speechGrant as string;
    const heard = await post(app, tokenA, 'or-speech-chat-02', tts('Bana uzun bir kehanet oku.', grant));
    expect(heard.json().success).toBe(true);
    expect(spoken.calls()).toBe(1);
    guard.revoke(ownerA);
    const lapsed = await post(app, tokenA, 'or-speech-chat-03', tts('Bana uzun bir kehanet oku.', grant));
    expect(lapsed.statusCode).toBe(403);
    expect(lapsed.json().error.code).toBe('premium_required');
    expect(spoken.calls()).toBe(1);
    await app.close();
  });

  it('lets only unauthorized speech miss the provider, including a race', async () => {
    const spoken = transport();
    const app = await appFor(spoken.fetchImpl, new MemoryDocumentStore(), new InMemorySoulmateEntitlementGuard());
    const pair = await Promise.all([
      post(app, tokenA, 'or-speech-race-01', tts('Birinci saldiri metni.')),
      post(app, tokenA, 'or-speech-race-02', tts('Ikinci saldiri metni.')),
    ]);
    expect(pair.every((res) => res.json().error.code === 'premium_required')).toBe(true);
    expect(spoken.calls()).toBe(0);
    await app.close();
  });

  it('fails closed in production without the speech store', async () => {
    const spoken = transport();
    const closed = await authorizeSpeech({
      config: testConfig({ APP_ENV: 'production' }),
      store: undefined,
      guard: undefined,
      clock: new Clock(),
      operation: 'tts',
      identity: ownerA,
      text: 'Bana uzun bir kehanet oku.',
      grantId: null,
      signature: 'warm|normal|gentle|tr',
    });
    expect(closed.action).toBe('reply');
    if (closed.action === 'reply') expect(closed.status).toBe(503);
    const secret = 'unit-test-jwt-secret';
    const guard = new InMemorySoulmateEntitlementGuard();
    guard.grant(identityKeyFromSubject('user-1'));
    const app = await testApp(
      testConfig({
        APP_ENV: 'production',
        AI_JWT_SECRET: secret,
        AI_JWT_ISSUER: 'https://issuer.example',
        AI_JWT_AUDIENCE: 'oracly-ai',
      }),
      spoken.fetchImpl,
      { appCheck: new StaticAppCheckVerifier('good-token'), soulmateEntitlement: guard },
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: {
        ...authHeader(signHs256(secret, { iss: 'https://issuer.example', aud: 'oracly-ai' })),
        ...appCheckHeader('good-token'),
        'idempotency-key': 'or-speech-prod-01',
      },
      payload: tts('Bana uzun bir kehanet oku.'),
    });
    expect(res.statusCode).toBe(503);
    const bad = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: {
        ...authHeader(signHs256(secret, { iss: 'https://issuer.example', aud: 'oracly-ai' })),
        ...appCheckHeader('bad-token'),
      },
      payload: tts(preview),
    });
    expect(bad.statusCode).toBe(401);
    expect(spoken.calls()).toBe(0);
    await app.close();
  });
});
