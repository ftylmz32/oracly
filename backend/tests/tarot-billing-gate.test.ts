import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import type { ServerClock } from '../src/reading/clock.js';
import { GEM_TAROT_READING_COST } from '../src/reading/gem-wallet-policy.js';
import {
  StaticAppCheckVerifier,
  appCheckHeader,
  authHeader,
  jsonResponse,
  signHs256,
  testApp,
  testConfig,
} from './helpers.js';

const SECRET = 'unit-test-jwt-secret';
const OP = 'or-tarot-session0001';

class Clock implements ServerClock {
  constructor(public ms = Date.UTC(2026, 9, 19)) {}
  now(): Date {
    return new Date(this.ms);
  }
}

const cards = [
  { name: 'The Fool', positionLabel: 'Geçmiş', reversed: false, meaning: 'Eşik.', keywords: ['başlangıç'] },
  { name: 'The Tower', positionLabel: 'Şimdi', reversed: true, meaning: 'Sarsıntı.', keywords: ['değişim'] },
  { name: 'The Star', positionLabel: 'Gelecek', reversed: false, meaning: 'Umut.', keywords: ['yön'] },
];

function reading(text: string) {
  return jsonResponse({ choices: [{ message: { content: text } }] });
}

function body(cardList = cards) {
  return {
    operation: 'tarot_reading',
    payload: { spreadLabel: 'Üç Kart', userQuestion: 'Ne görünür?', cards: cardList },
  };
}

async function world(balance = 40) {
  const store = new MemoryDocumentStore();
  const clock = new Clock();
  const ledger = new GemLedger(store, clock, provisionalGemCostPolicy());
  const owner = identityKeyFromSubject('user-a');
  if (balance > 0) {
    await ledger.credit({ ownerUserId: owner, amount: balance, idempotencyKey: 'seed-tarot-balance' });
  }
  let calls = 0;
  let text = 'Kartlar bu soruda bir eşik gösteriyor.';
  let failTimes = 0;
  const app = await testApp(
    testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' }),
    async () => {
      calls += 1;
      if (failTimes > 0) {
        failTimes -= 1;
        throw new Error('provider down');
      }
      return reading(text);
    },
    {
      appCheck: new StaticAppCheckVerifier('good-token'),
      readingClock: clock,
      gemLedger: ledger,
      gemStore: store,
    },
  );
  const headers = {
    ...authHeader(signHs256(SECRET, { sub: 'user-a' })),
    ...appCheckHeader('good-token'),
    'idempotency-key': OP,
  };
  return {
    app, store, clock, ledger, owner, headers,
    calls: () => calls,
    setText: (value: string) => { text = value; },
    failNext: (times = 1) => { failTimes = times; },
  };
}

function spends(store: MemoryDocumentStore): number {
  return [...store.docs.values()].filter((doc) => doc.type === 'spend' && doc.reason === 'tarot_reading').length;
}

describe('deep tarot server charge', () => {
  it('charges before the result and ignores a skipped settle', async () => {
    const setup = await world();
    const res = await setup.app.inject({
      method: 'POST', url: '/v1/ai/complete', headers: setup.headers, payload: body(),
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().data.text).toContain('eşik');
    expect(setup.calls()).toBe(1);
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(40 - GEM_TAROT_READING_COST);
    expect(spends(setup.store)).toBe(1);
    await setup.app.close();
  });

  it('replays settle on the same key without a second charge', async () => {
    const setup = await world();
    await setup.app.inject({
      method: 'POST', url: '/v1/ai/complete', headers: setup.headers, payload: body(),
    });
    const settle = await setup.app.inject({
      method: 'POST',
      url: `/v1/gems/tarot/${OP}/settle`,
      headers: setup.headers,
      payload: { idempotencyKey: 'tarot-settle-request-v1' },
    });
    expect(settle.statusCode).toBe(200);
    expect(settle.json().data.idempotent).toBe(true);
    expect(settle.json().data.balance).toBe(20);
    expect(settle.json().data.canonicalCost).toBe(20);
    expect(spends(setup.store)).toBe(1);
    await setup.app.close();
  });

  it('returns the saved reading when the response was lost', async () => {
    const setup = await world();
    const first = await setup.app.inject({
      method: 'POST', url: '/v1/ai/complete', headers: setup.headers, payload: body(),
    });
    const second = await setup.app.inject({
      method: 'POST', url: '/v1/ai/complete', headers: setup.headers, payload: body(),
    });
    expect(second.json().data.text).toBe(first.json().data.text);
    expect(setup.calls()).toBe(1);
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(20);
    await setup.app.close();
  });

  it('refuses a paid reading with no operation id and does not call the provider', async () => {
    const setup = await world();
    const { 'idempotency-key': _ignored, ...headers } = setup.headers;
    const res = await setup.app.inject({
      method: 'POST', url: '/v1/ai/complete', headers, payload: body(),
    });
    expect(res.json().error.code).toBe('invalid_request');
    expect(setup.calls()).toBe(0);
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(40);
    await setup.app.close();
  });

  it('leaves a one-card reading free', async () => {
    const setup = await world();
    const res = await setup.app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(signHs256(SECRET, { sub: 'user-a' })), ...appCheckHeader('good-token') },
      payload: body([cards[0]!]),
    });
    expect(res.statusCode).toBe(200);
    expect(setup.calls()).toBe(1);
    expect(spends(setup.store)).toBe(0);
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(40);
    await setup.app.close();
  });

  it('does not call the provider when the balance is short', async () => {
    const setup = await world(10);
    const res = await setup.app.inject({
      method: 'POST', url: '/v1/ai/complete', headers: setup.headers, payload: body(),
    });
    expect(res.statusCode).toBe(409);
    expect(res.json().error.code).toBe('insufficient_gems');
    expect(setup.calls()).toBe(0);
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(10);
    await setup.app.close();
  });

  it('refunds a provider failure and blocks a free retry of that operation', async () => {
    const setup = await world();
    setup.failNext();
    const failed = await setup.app.inject({
      method: 'POST', url: '/v1/ai/complete', headers: setup.headers, payload: body(),
    });
    expect(failed.json().error.code).toBe('provider_error');
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(40);
    const again = await setup.app.inject({
      method: 'POST', url: '/v1/ai/complete', headers: setup.headers, payload: body(),
    });
    expect(again.statusCode).toBe(409);
    expect(setup.calls()).toBe(1);
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(40);
    await setup.app.close();
  });

  it('keeps one charge across narrative attempt 1 and attempt 2', async () => {
    const setup = await world();
    setup.failNext();
    const first = await setup.app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...setup.headers, 'idempotency-key': `${OP}:nv2:a1` },
      payload: body(),
    });
    expect(first.json().error.code).toBe('provider_error');
    setup.setText('İkinci deneme aynı işlemi tamamlar.');
    const second = await setup.app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...setup.headers, 'idempotency-key': `${OP}:nv2:a2` },
      payload: body(),
    });
    expect(second.statusCode).toBe(200);
    expect(second.json().data.text).toContain('İkinci deneme');
    expect(setup.calls()).toBe(2);
    expect(spends(setup.store)).toBe(1);
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(20);
    await setup.app.close();
  });

  it('lets one of two concurrent requests through and charges once', async () => {
    const setup = await world();
    const send = () => setup.app.inject({
      method: 'POST', url: '/v1/ai/complete', headers: setup.headers, payload: body(),
    });
    const [a, b] = await Promise.all([send(), send()]);
    expect([a.statusCode, b.statusCode].every((code) => code === 200 || code === 409)).toBe(true);
    expect([a, b].some((res) => res.statusCode === 200)).toBe(true);
    expect(setup.calls()).toBe(1);
    expect(spends(setup.store)).toBe(1);
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(20);
    await setup.app.close();
  });

  it('resumes an abandoned in-flight claim without a second charge', async () => {
    const setup = await world();
    let release: ((value: Response) => void) | null = null;
    const hung = await testApp(
      testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' }),
      () => new Promise<Response>((resolve) => { release = resolve; }),
      {
        appCheck: new StaticAppCheckVerifier('good-token'),
        readingClock: setup.clock,
        gemLedger: setup.ledger,
        gemStore: setup.store,
      },
    );
    const pending = hung.inject({
      method: 'POST', url: '/v1/ai/complete', headers: setup.headers, payload: body(),
    });
    const deadline = Date.now() + 2000;
    while (![...setup.store.docs.keys()].some((path) => path.startsWith('tarotHolds/')) && Date.now() < deadline) {
      await new Promise((resolve) => setTimeout(resolve, 10));
    }
    const blocked = await hung.inject({
      method: 'POST', url: '/v1/ai/complete', headers: setup.headers, payload: body(),
    });
    expect(blocked.statusCode).toBe(409);
    for (const [path, doc] of setup.store.docs) {
      if (path.startsWith('tarotHolds/')) doc.claimUntilMs = 0;
    }
    const resumed = await setup.app.inject({
      method: 'POST', url: '/v1/ai/complete', headers: setup.headers, payload: body(),
    });
    expect(resumed.statusCode).toBe(200);
    expect(spends(setup.store)).toBe(1);
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(20);
    release?.(reading('Geç gelen cevap ayrıca ücretlenmez.'));
    await pending;
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(20);
    await hung.close();
    await setup.app.close();
  });

  it('refunds a stale empty hold when the wallet is read', async () => {
    const setup = await world();
    setup.failNext();
    await setup.app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...setup.headers, 'idempotency-key': `${OP}:nv2:a1` },
      payload: body(),
    });
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(20);
    setup.clock.ms += 16 * 60_000;
    const balance = await setup.app.inject({
      method: 'GET', url: '/v1/gems/balance', headers: setup.headers,
    });
    expect(balance.json().data.balance).toBe(40);
    await setup.app.close();
  });

  it('does not let another account spend or read this hold', async () => {
    const setup = await world();
    await setup.app.inject({
      method: 'POST', url: '/v1/ai/complete', headers: setup.headers, payload: body(),
    });
    const other = identityKeyFromSubject('user-b');
    const headers = {
      ...authHeader(signHs256(SECRET, { sub: 'user-b' })),
      ...appCheckHeader('good-token'),
      'idempotency-key': OP,
    };
    const denied = await setup.app.inject({
      method: 'POST', url: '/v1/ai/complete', headers, payload: body(),
    });
    expect(denied.statusCode).toBe(409);
    expect(denied.json().error.code).toBe('insufficient_gems');
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(20);
    expect(await setup.ledger.balanceOf(other)).toBe(0);
    await setup.app.close();
  });
});
