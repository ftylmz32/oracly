import { describe, expect, it } from 'vitest';
import { identityKeyFromOpaqueToken } from '../src/auth/identity.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import type { ServerClock } from '../src/reading/clock.js';
import {
  authHeader,
  jsonResponse,
  openaiText,
  testApp,
  testConfig,
} from './helpers.js';

const tokenA = 'user-access-token';
const tokenB = 'other-access-token';
const ownerA = identityKeyFromOpaqueToken(tokenA);
const ownerB = identityKeyFromOpaqueToken(tokenB);

class Clock implements ServerClock {
  constructor(public ms = Date.UTC(2026, 9, 19, 12)) {}
  now(): Date {
    return new Date(this.ms);
  }
}

function chat(n: number, extra: Record<string, unknown> = {}) {
  return {
    operation: 'chat',
    model: 'gpt-4o',
    userId: 'client-says-someone-else',
    payload: {
      userMessage: `Merhaba ${n}`,
      priorUser: [],
      dailyQuotaRemaining: 999,
      premium: true,
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

describe('free text daily quota', () => {
  it('allows 30, rejects the 31st, and ignores a client quota claim', async () => {
    let calls = 0;
    const fetchImpl: typeof fetch = async (url, init) => {
      if (String(url).includes('/chat/completions')) calls += 1;
      return openaiText('Sakin bir yanit.')(url, init);
    };
    const app = await testApp(testConfig({ AI_RATE_LIMIT_MAX: '100' }), fetchImpl, {
      freeTextQuotaStore: new MemoryDocumentStore(),
    });
    for (let n = 1; n <= 30; n += 1) {
      const res = await app.inject({
        method: 'POST',
        url: '/v1/ai/complete',
        headers: { ...authHeader(tokenA), 'idempotency-key': `or-chat-quota-${String(n).padStart(4, '0')}` },
        payload: chat(n),
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().success).toBe(true);
    }
    const blocked = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-chat-quota-0031' },
      payload: chat(31),
    });
    expect(blocked.statusCode).toBe(200);
    expect(blocked.json().error.code).toBe('daily_quota');
    expect(calls).toBe(30);
    await app.close();
  });

  it('lets only one of two concurrent requests take the last allowance', async () => {
    let calls = 0;
    const fetchImpl: typeof fetch = async (url, init) => {
      if (String(url).includes('/chat/completions')) calls += 1;
      return openaiText('Sakin bir yanit.')(url, init);
    };
    const app = await testApp(testConfig({ AI_RATE_LIMIT_MAX: '100' }), fetchImpl, {
      freeTextQuotaStore: new MemoryDocumentStore(),
    });
    for (let n = 1; n <= 29; n += 1) {
      const res = await app.inject({
        method: 'POST',
        url: '/v1/ai/complete',
        headers: { ...authHeader(tokenA), 'idempotency-key': `or-chat-race-${String(n).padStart(4, '0')}` },
        payload: chat(n),
      });
      expect(res.statusCode).toBe(200);
    }
    const pair = await Promise.all([30, 31].map((n) => app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': `or-chat-race-${String(n).padStart(4, '0')}` },
      payload: chat(n),
    })));
    const codes = pair.map((res) => res.json().error?.code ?? 'ok');
    expect(codes.filter((code) => code === 'ok')).toHaveLength(1);
    expect(codes.filter((code) => code === 'daily_quota')).toHaveLength(1);
    expect(calls).toBe(30);
    await app.close();
  });

  it('replays one operation without a second allowance or provider call', async () => {
    let calls = 0;
    const fetchImpl: typeof fetch = async (url, init) => {
      if (String(url).includes('/chat/completions')) calls += 1;
      return openaiText('Ayni yanit.')(url, init);
    };
    const app = await testApp(testConfig(), fetchImpl, {
      freeTextQuotaStore: new MemoryDocumentStore(),
    });
    const headers = { ...authHeader(tokenA), 'idempotency-key': 'or-chat-replay-0001' };
    const first = await app.inject({ method: 'POST', url: '/v1/ai/complete', headers, payload: chat(1) });
    const second = await app.inject({ method: 'POST', url: '/v1/ai/complete', headers, payload: chat(1) });
    expect(first.json().data.text).toBe('Ayni yanit.');
    expect(second.json().data.text).toBe('Ayni yanit.');
    expect(calls).toBe(1);
    const attempt = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-chat-replay-0001:yv1:a2' },
      payload: chat(2),
    });
    expect(attempt.json().success).toBe(true);
    expect(calls).toBe(2);
    await app.close();
  });

  it('returns the allowance when the provider fails, then serves the same operation', async () => {
    let armed = false;
    let failedOnce = false;
    let calls = 0;
    const fetchImpl: typeof fetch = async (url, init) => {
      calls += 1;
      if (armed && !failedOnce) {
        failedOnce = true;
        return jsonResponse({ error: { message: 'down' } }, 500);
      }
      return openaiText('Toparlandi.')(url, init);
    };
    const app = await testApp(testConfig({ AI_RATE_LIMIT_MAX: '100' }), fetchImpl, {
      freeTextQuotaStore: new MemoryDocumentStore(),
    });
    for (let n = 1; n <= 29; n += 1) {
      const res = await app.inject({
        method: 'POST',
        url: '/v1/ai/complete',
        headers: { ...authHeader(tokenA), 'idempotency-key': `or-chat-keep-${String(n).padStart(4, '0')}` },
        payload: chat(n),
      });
      expect(res.json().success).toBe(true);
    }
    armed = true;
    const failed = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-chat-fail-0001' },
      payload: chat(30),
    });
    expect(failed.json().success).toBe(false);
    const again = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-chat-fail-0001' },
      payload: chat(40),
    });
    expect(again.json().data.text).toBe('Toparlandi.');
    const blocked = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-chat-fail-0002' },
      payload: chat(32),
    });
    expect(blocked.json().error.code).toBe('daily_quota');
    expect(calls).toBe(31);
    await app.close();
  });

  it('opens a fresh allowance on the next server day and keeps accounts apart', async () => {
    let calls = 0;
    const fetchImpl: typeof fetch = async (url, init) => {
      if (String(url).includes('/chat/completions')) calls += 1;
      return openaiText('Yeni gun.')(url, init);
    };
    const clock = new Clock();
    const store = new MemoryDocumentStore();
    const app = await testApp(testConfig({ AI_RATE_LIMIT_MAX: '200' }), fetchImpl, {
      freeTextQuotaStore: store,
      readingClock: clock,
    });
    for (let n = 1; n <= 30; n += 1) {
      await app.inject({
        method: 'POST',
        url: '/v1/ai/complete',
        headers: { ...authHeader(tokenA), 'idempotency-key': `or-chat-day-${String(n).padStart(4, '0')}` },
        payload: chat(n),
      });
    }
    const other = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenB), 'idempotency-key': 'or-chat-other-0001' },
      payload: chat(1),
    });
    expect(other.json().success).toBe(true);
    clock.ms += 86_400_000;
    const next = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-chat-nextday-01' },
      payload: chat(99),
    });
    expect(next.json().success).toBe(true);
    expect(calls).toBe(32);
    expect(ownerA).not.toBe(ownerB);
    await app.close();
  });

  it('leaves deep tarot on the gem ledger and outside the free allowance', async () => {
    let calls = 0;
    const fetchImpl: typeof fetch = async (url, init) => {
      if (String(url).includes('/chat/completions')) calls += 1;
      return openaiText('Derin okuma.')(url, init);
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
    const app = await testApp(testConfig({ AI_RATE_LIMIT_MAX: '100' }), fetchImpl, {
      freeTextQuotaStore: store,
      gemLedger: ledger,
      gemStore: store,
      readingClock: clock,
    });
    for (let n = 1; n <= 30; n += 1) {
      const res = await app.inject({
        method: 'POST',
        url: '/v1/ai/complete',
        headers: { ...authHeader(tokenA), 'idempotency-key': `or-chat-gems-${String(n).padStart(4, '0')}` },
        payload: chat(n),
      });
      expect(res.json().success).toBe(true);
    }
    expect(await ledger.balanceOf(ownerA)).toBe(40);
    const paid = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-tarot-deepquota01' },
      payload: deepTarot,
    });
    expect(paid.json().success).toBe(true);
    expect(await ledger.balanceOf(ownerA)).toBe(20);
    const blocked = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(tokenA), 'idempotency-key': 'or-chat-gems-0031' },
      payload: chat(31),
    });
    expect(blocked.json().error.code).toBe('daily_quota');
    expect(calls).toBe(31);
    await app.close();
  });

  it('does not spend an allowance when the operation id is missing', async () => {
    let calls = 0;
    const fetchImpl: typeof fetch = async (url, init) => {
      calls += 1;
      return openaiText('Olmamali.')(url, init);
    };
    const app = await testApp(testConfig(), fetchImpl, {
      freeTextQuotaStore: new MemoryDocumentStore(),
    });
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(tokenA),
      payload: chat(1),
    });
    expect(res.json().error.code).toBe('invalid_request');
    expect(calls).toBe(0);
    await app.close();
  });
});
