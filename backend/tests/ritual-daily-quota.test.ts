import { describe, expect, it } from 'vitest';
import { identityKeyFromOpaqueToken } from '../src/auth/identity.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { GEM_DAILY_REWARD, GEM_TAROT_READING_COST } from '../src/reading/gem-wallet-policy.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import type { ServerClock } from '../src/reading/clock.js';
import { admitRitualQuota, ritualKindOf } from '../src/reading/ritual-daily-quota.js';
import { InMemorySoulmateEntitlementGuard } from '../src/reading/soulmate-entitlement-guard.js';
import { resetSoulmateUniquenessIndex } from '../src/ai/soulmate-uniqueness-index.js';
import {
  authHeader,
  coffeeBody,
  coffeeMeaningWriterJson,
  coffeeObserverJson,
  fakeJpeg,
  jsonResponse,
  openaiReadingSequence,
  palmBody,
  palmObserverJson,
  palmWriterJson,
  soulmateBody,
  testApp,
  testConfig,
} from './helpers.js';
import { ASTRA, passRaw, trFear } from './dream-phase4c3-support.js';

const tokenA = 'user-access-token';
const tokenB = 'other-access-token';
const ownerA = identityKeyFromOpaqueToken(tokenA);

class Clock implements ServerClock {
  constructor(public ms = Date.UTC(2026, 9, 19, 12)) {}
  now(): Date {
    return new Date(this.ms);
  }
}

function cycle(observer: string, writer: string): typeof fetch {
  let n = 0;
  return async () => {
    n += 1;
    const text = n % 2 === 1 ? observer : writer;
    return jsonResponse({ choices: [{ message: { content: text } }] });
  };
}

function dreamBody(extra: Record<string, unknown> = {}) {
  const { narrative, symbols, emotions, language } = trFear.payload as Record<string, unknown>;
  return {
    operation: 'dream_analysis',
    userId: 'spoof',
    payload: {
      narrative,
      symbols: symbols ?? [],
      emotions: emotions ?? [],
      language: language ?? 'tr',
      ...extra,
    },
  };
}

const deepTarot = {
  operation: 'tarot_reading',
  payload: {
    spreadLabel: 'Üç Kart',
    userQuestion: 'Ne üzerinde durayım?',
    cards: [
      { name: 'The Fool', positionLabel: 'Geçmiş', reversed: false, meaning: 'Eşik.', keywords: ['başlangıç'] },
      { name: 'The Tower', positionLabel: 'Şimdi', reversed: true, meaning: 'Sarsıntı.', keywords: ['değişim'] },
      { name: 'The Star', positionLabel: 'Gelecek', reversed: false, meaning: 'Umut.', keywords: ['yön'] },
    ],
  },
};

function appFor(
  fetchImpl: typeof fetch,
  store = new MemoryDocumentStore(),
  clock?: Clock,
  extra: Record<string, string> = {},
) {
  return testApp(testConfig({
    AI_RATE_LIMIT_MAX: '100',
    AI_EXPENSIVE_RATE_MAX: '30',
    ...extra,
  }), fetchImpl, {
    ritualQuotaStore: store,
    readingClock: clock,
  });
}

describe('ritual daily quota', () => {
  it('allows one coffee and rejects the second before the provider', async () => {
    let calls = 0;
    const inner = openaiReadingSequence(coffeeObserverJson, coffeeMeaningWriterJson);
    const fetchImpl: typeof fetch = async (url, init) => {
      calls += 1;
      return inner(url, init);
    };
    const app = await testApp(testConfig(), fetchImpl, { ritualQuotaStore: new MemoryDocumentStore() });
    const first = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(), 'idempotency-key': 'or-coffee-quota-0001' },
      payload: coffeeBody(),
    });
    expect(first.json().success, JSON.stringify(first.json())).toBe(true);
    const before = calls;
    const second = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-coffee-quota-0002' },
      payload: coffeeBody(fakeJpeg(9100)),
    });
    expect(second.json().error.code).toBe('coffee_daily_quota');
    expect(calls).toBe(before);
    await app.close();
  });

  it('allows two palm readings and rejects the third', async () => {
    let calls = 0;
    const inner = cycle(palmObserverJson, palmWriterJson);
    const fetchImpl: typeof fetch = async (url, init) => {
      calls += 1;
      return inner(url, init);
    };
    const app = await appFor(fetchImpl, new MemoryDocumentStore(), undefined, {
      ORACLY_PALM_ENGINE: 'structured',
    });
    for (const [n, size] of [[1, 9000], [2, 9200]] as const) {
      const res = await app.inject({
        method: 'POST',
        url: '/v1/ai/complete',
        headers: { ...authHeader(tokenA), 'idempotency-key': `or-palm-quota-000${n}` },
        payload: palmBody(fakeJpeg(size)),
      });
      expect(res.json().success, JSON.stringify(res.json())).toBe(true);
    }
    const before = calls;
    const third = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-palm-quota-0003' },
      payload: palmBody(fakeJpeg(9300)),
    });
    expect(third.json().error.code).toBe('palm_daily_quota');
    expect(calls).toBe(before);
    await app.close();
  });

  it('allows three dreams and rejects the fourth', async () => {
    let calls = 0;
    const fetchImpl: typeof fetch = async () => {
      calls += 1;
      return jsonResponse({ choices: [{ message: { content: passRaw } }] });
    };
    const app = await appFor(fetchImpl, new MemoryDocumentStore(), undefined, ASTRA);
    const realNow = Date.now;
    let now = realNow();
    Date.now = () => now;
    try {
      for (let n = 1; n <= 3; n += 1) {
        const res = await app.inject({
          method: 'POST',
          url: '/v1/ai/complete',
          headers: { ...authHeader(tokenA), 'idempotency-key': `or-dream-quota-000${n}` },
          payload: dreamBody(),
        });
        expect(res.json().success, JSON.stringify(res.json())).toBe(true);
        now += 6_000;
      }
      const before = calls;
      const blocked = await app.inject({
        method: 'POST',
        url: '/v1/ai/complete',
        headers: { ...authHeader(tokenA), 'idempotency-key': 'or-dream-quota-0004' },
        payload: dreamBody(),
      });
      expect(blocked.json().error.code).toBe('dream_daily_quota');
      expect(calls).toBe(before);
    } finally {
      Date.now = realNow;
    }
    await app.close();
  });

  it('lets only one coffee take the last allowance', async () => {
    let calls = 0;
    const inner = openaiReadingSequence(coffeeObserverJson, coffeeMeaningWriterJson);
    const fetchImpl: typeof fetch = async (url, init) => {
      calls += 1;
      return inner(url, init);
    };
    const app = await appFor(fetchImpl);
    const pair = await Promise.all([9000, 9400].map((size, index) => app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': `or-coffee-race-000${index + 1}` },
      payload: coffeeBody(fakeJpeg(size)),
    })));
    const codes = pair.map((res) => res.json().error?.code ?? 'ok');
    expect(codes.filter((code) => code === 'ok')).toHaveLength(1);
    expect(codes.filter((code) => code === 'coffee_daily_quota')).toHaveLength(1);
    expect(calls).toBe(2);
    await app.close();
  });

  it('replays a stored coffee without a second allowance or provider call', async () => {
    let calls = 0;
    const inner = openaiReadingSequence(coffeeObserverJson, coffeeMeaningWriterJson);
    const fetchImpl: typeof fetch = async (url, init) => {
      calls += 1;
      return inner(url, init);
    };
    const app = await appFor(fetchImpl);
    const headers = { ...authHeader(tokenA), 'idempotency-key': 'or-coffee-replay-001' };
    const payload = coffeeBody();
    const first = await app.inject({ method: 'POST', url: '/v1/ai/complete', headers, payload });
    const second = await app.inject({ method: 'POST', url: '/v1/ai/complete', headers, payload });
    expect(second.json().data.overall).toBe(first.json().data.overall);
    expect(calls).toBe(2);
    await app.close();
  });

  it('returns the coffee allowance when the provider fails', async () => {
    let calls = 0;
    let fail = true;
    const inner = openaiReadingSequence(coffeeObserverJson, coffeeMeaningWriterJson);
    const fetchImpl: typeof fetch = async (url, init) => {
      calls += 1;
      if (fail) {
        fail = false;
        return jsonResponse({ error: { message: 'down' } }, 500);
      }
      return inner(url, init);
    };
    const app = await appFor(fetchImpl);
    const failed = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-coffee-fail-0001' },
      payload: coffeeBody(fakeJpeg(9000)),
    });
    expect(failed.json().success).toBe(false);
    const again = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-coffee-fail-0001' },
      payload: coffeeBody(fakeJpeg(9500)),
    });
    expect(again.json().success).toBe(true);
    const blocked = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-coffee-fail-0002' },
      payload: coffeeBody(fakeJpeg(9600)),
    });
    expect(blocked.json().error.code).toBe('coffee_daily_quota');
    await app.close();
  });

  it('opens a fresh coffee allowance on the next server day and keeps accounts apart', async () => {
    let calls = 0;
    const inner = cycle(coffeeObserverJson, coffeeMeaningWriterJson);
    const fetchImpl: typeof fetch = async (url, init) => {
      calls += 1;
      return inner(url, init);
    };
    const clock = new Clock();
    const app = await appFor(fetchImpl, new MemoryDocumentStore(), clock);
    const used = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-coffee-day-0001' },
      payload: coffeeBody(fakeJpeg(9000)),
    });
    expect(used.json().success).toBe(true);
    const other = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenB), 'idempotency-key': 'or-coffee-day-0002' },
      payload: coffeeBody(fakeJpeg(9100)),
    });
    expect(other.json().success).toBe(true);
    clock.ms += 86_400_000;
    const next = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-coffee-day-0003' },
      payload: coffeeBody(fakeJpeg(9700)),
    });
    expect(next.json().success).toBe(true);
    expect(calls).toBe(6);
    await app.close();
  });

  it('does not spend an allowance on an invalid image or a missing operation id', async () => {
    let calls = 0;
    const inner = openaiReadingSequence(coffeeObserverJson, coffeeMeaningWriterJson);
    const fetchImpl: typeof fetch = async (url, init) => {
      calls += 1;
      return inner(url, init);
    };
    const app = await appFor(fetchImpl);
    const missing = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(tokenA),
      payload: coffeeBody(),
    });
    expect(missing.json().error.code).toBe('invalid_request');
    const tiny = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-coffee-tiny-0001' },
      payload: coffeeBody(Buffer.from([0xff, 0xd8, 0xff, 1, 2, 3])),
    });
    expect(tiny.json().error.code).toBe('invalid_image');
    const ok = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-coffee-tiny-0002' },
      payload: coffeeBody(),
    });
    expect(ok.json().success).toBe(true);
    expect(calls).toBe(2);
    await app.close();
  });

  it('keeps a delivered coffee when the client opens another, and leaves gems and premium alone', async () => {
    resetSoulmateUniquenessIndex();
    let calls = 0;
    const inner = cycle(coffeeObserverJson, coffeeMeaningWriterJson);
    const fetchImpl: typeof fetch = async (url, init) => {
      calls += 1;
      const raw = String(init?.body ?? '');
      if (raw.includes('The Fool') || raw.includes('userMessage')) {
        return jsonResponse({ choices: [{ message: { content: 'Derin okuma.' } }] });
      }
      return inner(url, init);
    };
    const clock = new Clock();
    const store = new MemoryDocumentStore();
    const ledger = new GemLedger(store, clock, provisionalGemCostPolicy());
    await ledger.credit({
      ownerUserId: ownerA,
      amount: 40,
      idempotencyKey: 'starter-grant-v1',
      reason: 'starter_grant',
    });
    const app = await testApp(testConfig({ AI_RATE_LIMIT_MAX: '100', AI_EXPENSIVE_RATE_MAX: '30' }), fetchImpl, {
      ritualQuotaStore: store,
      gemLedger: ledger,
      gemStore: store,
      readingClock: clock,
      soulmateEntitlement: new InMemorySoulmateEntitlementGuard(),
    });
    expect(GEM_DAILY_REWARD).toBe(25);
    expect(GEM_TAROT_READING_COST).toBe(20);
    expect(ritualKindOf('soulmate_draw')).toBeNull();
    const coffee = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-coffee-gems-0001' },
      payload: coffeeBody(),
    });
    expect(coffee.json().success, JSON.stringify(coffee.json())).toBe(true);
    expect(await ledger.balanceOf(ownerA)).toBe(40);
    const paid = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-tarot-ritualgem01' },
      payload: deepTarot,
    });
    expect(paid.json().success).toBe(true);
    expect(await ledger.balanceOf(ownerA)).toBe(20);
    const soulmate = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(tokenA),
      payload: soulmateBody,
    });
    expect(soulmate.statusCode).toBe(403);
    expect(soulmate.json().error.code).toBe('forbidden');
    const chat = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-chat-ritual-0001' },
      payload: { operation: 'chat', payload: { userMessage: 'Merhaba', priorUser: [] } },
    });
    expect(chat.statusCode).toBe(200);
    expect(chat.json().error?.code).not.toBe('coffee_daily_quota');
    await app.close();
    expect(calls).toBeGreaterThan(0);
  });

  it('keeps an abandoned hold so a new operation cannot take a free call', async () => {
    const store = new MemoryDocumentStore();
    const clock = new Clock();
    const config = testConfig();
    const first = await admitRitualQuota({
      config, store, clock, operation: 'coffee_analysis', identity: ownerA, idempotencyKey: 'or-coffee-abort-0001',
    });
    expect(first.action).toBe('hold');
    const second = await admitRitualQuota({
      config, store, clock, operation: 'coffee_analysis', identity: ownerA, idempotencyKey: 'or-coffee-abort-0002',
    });
    expect(second.action).toBe('reply');
    if (second.action === 'reply') {
      expect(JSON.stringify(second.payload)).toContain('coffee_daily_quota');
    }
  });

  it('fails closed in production when the quota store is missing', async () => {
    const result = await admitRitualQuota({
      config: testConfig({ APP_ENV: 'production' }),
      store: undefined,
      clock: new Clock(),
      operation: 'dream_analysis',
      identity: ownerA,
      idempotencyKey: 'or-dream-locked-0001',
    });
    expect(result.action).toBe('reply');
    if (result.action === 'reply') expect(result.status).toBe(503);
  });
});
