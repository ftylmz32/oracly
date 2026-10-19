import { describe, expect, it } from 'vitest';
import { identityKeyFromOpaqueToken } from '../src/auth/identity.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import type { ServerClock } from '../src/reading/clock.js';
import { admitLunaText } from '../src/reading/luna-premium-gate.js';
import { InMemorySoulmateEntitlementGuard } from '../src/reading/soulmate-entitlement-guard.js';
import {
  authHeader,
  jsonResponse,
  oracleBody,
  palmOracleBody,
  testApp,
  testConfig,
} from './helpers.js';

const tokenA = 'user-access-token';
const tokenB = 'other-access-token';
const ownerA = identityKeyFromOpaqueToken(tokenA);

class Clock implements ServerClock {
  now(): Date {
    return new Date(Date.UTC(2026, 9, 19, 12));
  }
}

function textFetch(): { fetch: typeof fetch; calls: () => number } {
  let calls = 0;
  const fetchImpl: typeof fetch = async () => {
    calls += 1;
    return jsonResponse({ choices: [{ message: { content: 'Sakin bir yansıma.' } }] });
  };
  return { fetch: fetchImpl, calls: () => calls };
}

function appFor(
  fetchImpl: typeof fetch,
  store: MemoryDocumentStore,
  guard: InMemorySoulmateEntitlementGuard,
) {
  return testApp(testConfig({ AI_RATE_LIMIT_MAX: '100' }), fetchImpl, {
    lunaAccessStore: store,
    freeTextQuotaStore: store,
    soulmateEntitlement: guard,
    readingClock: new Clock(),
  });
}

function quotaCount(store: MemoryDocumentStore): number {
  for (const [path, data] of store.docs) {
    if (path.startsWith('freeTextQuota/')) return Number(data.count ?? 0);
  }
  return 0;
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

describe('luna premium text', () => {
  it('allows one tarot oracle and then requires premium', async () => {
    const transport = textFetch();
    const store = new MemoryDocumentStore();
    const guard = new InMemorySoulmateEntitlementGuard();
    const app = await appFor(transport.fetch, store, guard);
    const first = await post(app, tokenA, 'or-luna-free-0001', oracleBody);
    expect(first.json().success, JSON.stringify(first.json())).toBe(true);
    expect(quotaCount(store)).toBe(1);
    const again = await post(app, tokenA, 'or-luna-free-0002', {
      operation: 'oracle',
      payload: {
        ...(oracleBody.payload as object),
        userMessage: 'Bu kart bana baska ne soyluyor?',
        premium: true,
        userId: 'spoof',
      },
    });
    expect(again.statusCode).toBe(403);
    expect(again.json().error.code).toBe('premium_required');
    expect(transport.calls()).toBe(1);
    expect(quotaCount(store)).toBe(1);
    const replay = await post(app, tokenA, 'or-luna-free-0001', oracleBody);
    expect(replay.json().success).toBe(true);
    expect(transport.calls()).toBe(1);
    await app.close();
  });

  it('does not let a new chat or a palm oracle spend the free tarot turn', async () => {
    const transport = textFetch();
    const store = new MemoryDocumentStore();
    const guard = new InMemorySoulmateEntitlementGuard();
    const app = await appFor(transport.fetch, store, guard);
    const chat = await post(app, tokenA, 'or-luna-chat-0001', {
      operation: 'chat',
      payload: {
        userMessage: 'Merhaba, bugun nasilsin?',
        priorUser: [],
        premium: true,
      },
    });
    expect(chat.json().error.code).toBe('premium_required');
    const palm = await post(app, tokenA, 'or-luna-palm-0001', palmOracleBody);
    expect(palm.json().error.code).toBe('premium_required');
    const free = await post(app, tokenA, 'or-luna-free-0003', oracleBody);
    expect(free.json().success).toBe(true);
    expect(transport.calls()).toBe(1);
    await app.close();
  });

  it('lets only one concurrent free oracle reach the provider', async () => {
    const transport = textFetch();
    const store = new MemoryDocumentStore();
    const guard = new InMemorySoulmateEntitlementGuard();
    const app = await appFor(transport.fetch, store, guard);
    const pair = await Promise.all([
      post(app, tokenA, 'or-luna-race-0001', oracleBody),
      post(app, tokenA, 'or-luna-race-0002', oracleBody),
    ]);
    const codes = pair.map((res) => res.json().success ? 'ok' : res.json().error.code);
    expect(codes.filter((code) => code === 'ok')).toHaveLength(1);
    expect(codes.filter((code) => code === 'premium_required' || code === 'rate_limited')).toHaveLength(1);
    expect(transport.calls()).toBe(1);
    await app.close();
  });

  it('keeps accounts apart and restores the free turn after a provider failure', async () => {
    let fail = true;
    let calls = 0;
    const fetchImpl: typeof fetch = async () => {
      calls += 1;
      if (fail) {
        fail = false;
        return jsonResponse({ error: { message: 'down' } }, 500);
      }
      return jsonResponse({ choices: [{ message: { content: 'Sakin bir yansıma.' } }] });
    };
    const store = new MemoryDocumentStore();
    const guard = new InMemorySoulmateEntitlementGuard();
    const app = await appFor(fetchImpl, store, guard);
    const realNow = Date.now;
    let now = realNow();
    Date.now = () => now;
    try {
      const broken = await post(app, tokenA, 'or-luna-fail-0001', oracleBody);
      expect(broken.json().success).toBe(false);
      now += 2_000;
      const retried = await post(app, tokenA, 'or-luna-fail-0001', oracleBody);
      expect(retried.json().success, JSON.stringify(retried.json())).toBe(true);
      now += 2_000;
      const other = await post(app, tokenB, 'or-luna-other-0001', oracleBody);
      expect(other.json().success).toBe(true);
      now += 2_000;
      const blocked = await post(app, tokenA, 'or-luna-fail-0002', oracleBody);
      expect(blocked.json().error.code).toBe('premium_required');
      expect(calls).toBe(3);
    } finally {
      Date.now = realNow;
    }
    await app.close();
  });

  it('allows an active premium chat and stops it when the snapshot lapses', async () => {
    const transport = textFetch();
    const store = new MemoryDocumentStore();
    const guard = new InMemorySoulmateEntitlementGuard();
    guard.grant(ownerA);
    const app = await appFor(transport.fetch, store, guard);
    const paid = await post(app, tokenA, 'or-luna-paid-0001', {
      operation: 'chat',
      payload: { userMessage: 'Premium yazışma.', priorUser: [] },
    });
    expect(paid.json().success, JSON.stringify(paid.json())).toBe(true);
    guard.revoke(ownerA);
    const lapsed = await post(app, tokenA, 'or-luna-paid-0002', {
      operation: 'chat',
      payload: { userMessage: 'Hak düşünce yazışma.', priorUser: [] },
    });
    expect(lapsed.statusCode).toBe(403);
    expect(lapsed.json().error.code).toBe('premium_required');
    expect(transport.calls()).toBe(1);
    await app.close();
  });

  it('still speaks and skips non-luna operations without premium', async () => {
    let calls = 0;
    const bytes = Buffer.from('ID3fake-oracly-tts-audio-bytes-here!!');
    const fetchImpl: typeof fetch = async () => {
      calls += 1;
      return new Response(bytes, { status: 200, headers: { 'content-type': 'audio/mpeg' } });
    };
    const store = new MemoryDocumentStore();
    const guard = new InMemorySoulmateEntitlementGuard();
    const app = await appFor(fetchImpl, store, guard);
    const spoken = await post(app, tokenA, 'or-luna-tts-00001', {
      operation: 'tts',
      payload: { text: 'Kısa bir ses.', personality: 'gentle', language: 'tr' },
    });
    expect(spoken.json().success, JSON.stringify(spoken.json())).toBe(true);
    expect(calls).toBe(1);
    expect(quotaCount(store)).toBe(0);
    const skipped = await admitLunaText({
      config: testConfig({ APP_ENV: 'production' }),
      store,
      guard,
      operation: 'yildizname_reading',
      oracleKind: null,
      identity: ownerA,
      idempotencyKey: 'or-luna-star-0001',
    });
    expect(skipped.action).toBe('skip');
    await app.close();
  });

  it('fails closed in production when the luna store is missing', async () => {
    const denied = await admitLunaText({
      config: testConfig({ APP_ENV: 'production' }),
      store: undefined,
      guard: new InMemorySoulmateEntitlementGuard(),
      operation: 'chat',
      oracleKind: null,
      identity: ownerA,
      idempotencyKey: 'or-luna-lock-0001',
    });
    expect(denied.action).toBe('reply');
    if (denied.action === 'reply') expect(denied.status).toBe(503);
  });
});
