/**
 * With reading commerce on, `/v1/ai/complete` palm_analysis cannot produce a
 * new Palm reading without a server credit. A paid Palm runs only through
 * `/v1/reading-operations` and the worker. The public route may only finish a
 * legacy Palm operation made before the rollout (it waited; paid Palm is
 * instant), owned by the caller and already claimed, and only under one
 * request key per operation, so a claimed operation cannot buy repeated
 * readings. Delivered readings still replay. With commerce off nothing changes.
 *
 * The provider is a counting fake; no real AI and no store.
 */
import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import type { OpenAiFetch } from '../src/types.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../src/reading/operation-staged-image-service.js';
import { ReadingFlow } from '../src/reading/reading-flow.js';
import { ReadingEntitlementLedger } from '../src/reading/reading-entitlement-ledger.js';
import { admitRitualQuota } from '../src/reading/ritual-daily-quota.js';
import { finishRitualQuota } from '../src/reading/ritual-daily-quota-settle.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import type { ServerClock } from '../src/reading/clock.js';
import {
  StaticAppCheckVerifier,
  appCheckHeader,
  authHeader,
  chatBody,
  fakeJpeg,
  palmBody,
  signHs256,
  testApp,
  testConfig,
} from './helpers.js';

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date {
    return new Date(this.ms);
  }
}

const SECRET = 'unit-test-jwt-secret';
const NOW = Date.parse('2026-10-27T10:00:00.000Z');
const WAIT = { coffee: 2 * 60 * 60 * 1000, palm: 4 * 60 * 60 * 1000, soulmate: 1000 };
const INTENTION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';

function backend() {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(NOW);
  const repository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(repository, clock, provisionalWaitPolicy(WAIT));
  const entitlements = new ReadingEntitlementLedger(store);
  const gems = new GemLedger(store, clock, provisionalGemCostPolicy());
  const flow = new ReadingFlow(store, clock, operations, gems, entitlements);
  const stagedImages = new ReadingStagedImageService(
    new FirestoreReadingStagedImageRepository(store),
    new MemoryStagedObjectStore(),
    operations,
    clock,
    testConfig({ READING_STAGING_BUCKET: 'test-bucket' }),
  );
  const provider = { calls: 0 };
  const fetchImpl: OpenAiFetch = async () => {
    provider.calls += 1;
    throw new Error('test provider: no real AI');
  };

  async function app(commerce: boolean, withPinStore = true) {
    return testApp(testConfig({
      AI_JWT_SECRET: SECRET,
      AI_APP_CHECK_REQUIRED: 'true',
      AI_DAILY_SPEND_CAP_USD: '5',
      OPENAI_API_KEY: 'sk-test-not-real',
      OPENAI_VISION: 'true',
      ORACLY_COFFEE_V3_ENABLED: 'true',
      READING_STAGING_BUCKET: 'test-bucket',
      ...(commerce ? { ORACLY_READING_COMMERCE_ENABLED: 'true' } : {}),
    }), fetchImpl, {
      appCheck: new StaticAppCheckVerifier('good-token'),
      readingOperationRepository: repository,
      readingClock: clock,
      readingWaitPolicy: provisionalWaitPolicy(WAIT),
      gemStore: store,
      gemLedger: gems,
      readingFlow: flow,
      ritualQuotaStore: withPinStore ? store : undefined,
      readingStagedImages: stagedImages,
    });
  }

  const headers = (sub = 'user-a', extra: Record<string, string> = {}) => ({
    ...authHeader(signHs256(SECRET, { sub })),
    ...appCheckHeader('good-token'),
    ...extra,
  });

  const count = (prefix: string) =>
    [...store.docs.keys()].filter((key) => key.startsWith(`${prefix}/`)).length;

  async function buy(sub: string, productId: string, n = 1) {
    await entitlements.grantPurchase({
      ownerUserId: identityKeyFromSubject(sub), platform: 'android', appId: 'app.oracly',
      productId: productId as never, purchaseToken: `tok-${sub}-${productId}-${n}`,
      transactionId: `GPA.${sub}.${n}`, atMs: NOW,
    });
  }

  /** A Palm operation created before the rollout (commerce off), staged, past its wait and claimed. */
  async function legacyPalm(sub = 'user-a', source = 'old-palm-00001', claim = true) {
    const before = await app(false);
    const made = await before.inject({
      method: 'POST', url: '/v1/reading-operations', headers: headers(sub),
      payload: { readingType: 'palm', sourceRequestId: source },
    });
    await before.close();
    const operationId = made.json().data.operationId as string;
    await stagedImages.stage({
      ownerUserId: identityKeyFromSubject(sub), operationId, mimeType: 'image/jpeg',
      imageBase64: fakeJpeg(12_000).toString('base64'), handSide: 'right',
    });
    if (claim) {
      clock.ms = Math.max(clock.ms, NOW + WAIT.palm + 1);
      expect((await flow.claim(identityKeyFromSubject(sub), operationId)).execute).toBe(true);
    }
    return operationId;
  }

  return {
    store, clock, repository, operations, entitlements, gems, flow, stagedImages, provider,
    app, headers, count, buy, legacyPalm,
  };
}

type App = Awaited<ReturnType<ReturnType<typeof backend>['app']>>;

function staged(app: App, headers: Record<string, string>, operationId: string, extra: Record<string, unknown> = {}) {
  return app.inject({
    method: 'POST', url: '/v1/ai/complete', headers,
    payload: { operation: 'palm_analysis', payload: { mimeType: 'image/jpeg', operationId, hand: 'right', ...extra } },
  });
}

const DENIED = 'reading_entitlement_required';

describe('commerce on: palm_analysis cannot start a free Palm reading', () => {
  it('a direct photo is refused before the provider; no quota, credit, gem or operation is used',
    async () => {
      const b = backend();
      const owner = identityKeyFromSubject('user-a');
      await b.buy('user-a', 'app.oracly.reading.palm');
      await b.gems.credit({ ownerUserId: owner, amount: 25, idempotencyKey: 'seed-gems-01' });
      const app = await b.app(true);
      const res = await app.inject({
        method: 'POST', url: '/v1/ai/complete',
        headers: b.headers('user-a', { 'idempotency-key': 'direct-palm-0001' }),
        payload: palmBody(),
      });
      expect(res.statusCode).toBe(403);
      expect(res.json()).toMatchObject({ success: false, error: { code: DENIED } });
      expect(b.provider.calls).toBe(0);
      expect(b.count('readingOperations')).toBe(0);
      expect((await b.entitlements.balance(owner)).palm).toBe(1);
      expect(await b.gems.balanceOf(owner)).toBe(25);
      const slot = await admitRitualQuota({
        config: testConfig(), store: b.store, clock: b.clock, operation: 'palm_analysis',
        identity: owner, idempotencyKey: 'probe-slot-0001',
      });
      expect(slot.action).toBe('hold');
      await app.close();
    });

  it('client payment claims and crafted tokens do not unlock it', async () => {
    const b = backend();
    const app = await b.app(true);
    const forged = palmBody();
    (forged.payload as Record<string, unknown>).paid = true;
    (forged.payload as Record<string, unknown>).entitlement = 'palm';
    (forged.payload as Record<string, unknown>).purchaseToken = 'valid-palm-1';
    // Forged fields inside the payload reach the commerce gate and change nothing.
    const inPayload = await app.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: b.headers('user-a', { 'idempotency-key': 'forged-palm-0001' }),
      payload: forged,
    });
    expect(inPayload.statusCode).toBe(403);
    expect(inPayload.json().error.code).toBe(DENIED);
    // A forged top-level field is refused by request validation (HTTP 200 envelope).
    const topLevel = await app.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: b.headers('user-a', { 'idempotency-key': 'forged-palm-0002' }),
      payload: { ...forged, paid: true },
    });
    expect(topLevel.json()).toEqual({ success: false, error: { code: 'invalid_request' } });
    expect(b.provider.calls).toBe(0);
    await app.close();
  });

  it('a call with no operation, an unknown one, or a write phase without one is refused', async () => {
    const b = backend();
    const app = await b.app(true);
    const h = (key: string) => b.headers('user-a', { 'idempotency-key': key });
    expect((await staged(app, h('unknown-op-0001'), '0123456789abcdef0123456789abcdef')).json().error.code).toBe(DENIED);
    const write = await app.inject({
      method: 'POST', url: '/v1/ai/complete', headers: h('write-noop-0001'),
      payload: { operation: 'palm_analysis', payload: { readingPhase: 'write', observationToken: 'x'.repeat(40), hand: 'right' } },
    });
    expect(write.json().error.code).toBe(DENIED);
    expect(b.provider.calls).toBe(0);
    await app.close();
  });

  it('a waiting (unclaimed) legacy Palm operation is refused', async () => {
    const b = backend();
    const operationId = await b.legacyPalm('user-a', 'old-palm-00002', false);
    const app = await b.app(true);
    const res = await staged(app, b.headers('user-a', { 'idempotency-key': 'waiting-palm-01' }), operationId);
    expect(res.json().error.code).toBe(DENIED);
    expect(b.provider.calls).toBe(0);
    await app.close();
  });

  it("another account cannot use the owner's claimed Palm operation", async () => {
    const b = backend();
    const operationId = await b.legacyPalm('user-a');
    const app = await b.app(true);
    const res = await staged(app, b.headers('user-b', { 'idempotency-key': 'foreign-palm-01' }), operationId);
    expect(res.json().error.code).toBe(DENIED);
    expect(b.provider.calls).toBe(0);
    await app.close();
  });

  it('a claimed Coffee or Soulmate operation cannot be read as palm_analysis', async () => {
    const b = backend();
    const owner = identityKeyFromSubject('user-a');
    const before = await b.app(false);
    const ids: string[] = [];
    for (const body of [{ readingType: 'coffee' }, { readingType: 'soulmate' }]) {
      const res = await before.inject({
        method: 'POST', url: '/v1/reading-operations', headers: b.headers(),
        payload: { ...body, sourceRequestId: `other-${body.readingType}-01` },
      });
      ids.push(res.json().data.operationId);
    }
    await before.close();
    b.clock.ms += WAIT.coffee + WAIT.palm;
    for (const id of ids) await b.flow.claim(owner, id);
    const app = await b.app(true);
    for (const [i, id] of ids.entries()) {
      const res = await staged(app, b.headers('user-a', { 'idempotency-key': `other-type-0${i}` }), id);
      expect(res.json().error.code).toBe(DENIED);
    }
    expect(b.provider.calls).toBe(0);
    await app.close();
  });

  it('a paid (instant) Palm operation is fulfilled by the worker only, never by the public route',
    async () => {
      const b = backend();
      const owner = identityKeyFromSubject('user-a');
      await b.buy('user-a', 'app.oracly.reading.palm');
      const app = await b.app(true);
      const created = await app.inject({
        method: 'POST', url: '/v1/reading-operations', headers: b.headers(),
        payload: { readingType: 'palm', sourceRequestId: 'paid-palm-0001' },
      });
      expect(created.statusCode).toBe(200);
      expect(created.json().data.remainingMs).toBe(0);
      const operationId = created.json().data.operationId as string;
      await b.stagedImages.stage({
        ownerUserId: owner, operationId, mimeType: 'image/jpeg',
        imageBase64: fakeJpeg(12_000).toString('base64'), handSide: 'right',
      });
      expect((await b.flow.claim(owner, operationId)).execute).toBe(true);
      const res = await staged(app, b.headers('user-a', { 'idempotency-key': 'paid-direct-01' }), operationId);
      expect(res.json().error.code).toBe(DENIED);
      expect(b.provider.calls).toBe(0);
      expect((await b.entitlements.balance(owner)).palm).toBe(0); // the one credit stays on its operation
      await app.close();
    });

  it('repeated and parallel direct attempts never reach the provider', async () => {
    const b = backend();
    const app = await b.app(true);
    const results = await Promise.all(Array.from({ length: 6 }, (_, i) => app.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: b.headers('user-a', { 'idempotency-key': i % 2 ? 'same-palm-key-01' : `par-palm-key-0${i}` }),
      payload: palmBody(),
    })));
    for (const res of results) expect(res.json().success).toBe(false);
    expect(results.filter((r) => r.json().error.code === DENIED).length).toBeGreaterThan(0);
    expect(b.provider.calls).toBe(0);
    await app.close();
  });
});

describe('commerce on: legacy Palm operations made before the rollout', () => {
  it('a claimed one is fulfilled under its own request key (observe then write)', async () => {
    const b = backend();
    const operationId = await b.legacyPalm();
    const app = await b.app(true);
    const observe = await staged(app, b.headers('user-a', { 'idempotency-key': 'legacy-palm-key:observe' }), operationId, { readingPhase: 'observe' });
    expect(observe.json().error?.code).not.toBe(DENIED);
    expect(b.provider.calls).toBeGreaterThan(0); // reached the (fake) provider
    const write = await staged(app, b.headers('user-a', { 'idempotency-key': 'legacy-palm-key:write' }), operationId, {
      readingPhase: 'write', observationToken: 'x'.repeat(40),
    });
    expect(write.json().error?.code).not.toBe(DENIED);
    await app.close();
  });

  it('a second, different request key cannot buy another reading for the same operation', async () => {
    const b = backend();
    const operationId = await b.legacyPalm();
    const app = await b.app(true);
    await staged(app, b.headers('user-a', { 'idempotency-key': 'first-palm-key-01' }), operationId);
    const calls = b.provider.calls;
    expect(calls).toBeGreaterThan(0);
    const again = await staged(app, b.headers('user-a', { 'idempotency-key': 'second-palm-key-1' }), operationId);
    expect(again.json().error.code).toBe(DENIED);
    expect(b.provider.calls).toBe(calls);
    await app.close();
  });

  it('parallel different keys on one claimed operation: only one gets through', async () => {
    const b = backend();
    const operationId = await b.legacyPalm();
    const app = await b.app(true);
    const results = await Promise.all(Array.from({ length: 5 }, (_, i) =>
      staged(app, b.headers('user-a', { 'idempotency-key': `race-palm-key-0${i}` }), operationId)));
    const passed = results.filter((r) => r.json().error?.code !== DENIED);
    expect(passed).toHaveLength(1);
    await app.close();
  });

  it('a claimed one without a request key is refused', async () => {
    const b = backend();
    const operationId = await b.legacyPalm();
    const app = await b.app(true);
    const res = await staged(app, b.headers('user-a'), operationId);
    // The free-slot check refuses a keyless call first (invalid_request); never served.
    expect(res.json().success).toBe(false);
    expect(b.provider.calls).toBe(0);
    expect(b.count('readingLegacyDirectAi')).toBe(0);
    await app.close();
  });

  it('without a store to pin the request key, a claimed operation is refused (fail closed)', async () => {
    const b = backend();
    const operationId = await b.legacyPalm();
    const app = await b.app(true, false);
    const res = await staged(app, b.headers('user-a', { 'idempotency-key': 'no-pin-store-01' }), operationId);
    expect(res.json().error.code).toBe(DENIED);
    expect(b.provider.calls).toBe(0);
    await app.close();
  });

  it('a paid Palm retry after its credit was refunded is still refused (paid path unchanged)', async () => {
    const b = backend();
    const owner = identityKeyFromSubject('user-a');
    await b.buy('user-a', 'app.oracly.reading.palm');
    const app = await b.app(true);
    const body = { readingType: 'palm', sourceRequestId: 'paid-palm-retry1' };
    const first = await app.inject({ method: 'POST', url: '/v1/reading-operations', headers: b.headers(), payload: body });
    const operationId = first.json().data.operationId as string;
    await b.flow.failFinal({ ownerUserId: owner, operationId, failureCode: 'unavailable' });
    expect((await b.entitlements.balance(owner)).palm).toBe(1);
    const retry = await app.inject({ method: 'POST', url: '/v1/reading-operations', headers: b.headers(), payload: body });
    expect(retry.statusCode).toBe(409);
    expect((await b.entitlements.balance(owner)).palm).toBe(1);
    await app.close();
  });

  it('status, create retry, claim and fail still work', async () => {
    const b = backend();
    const owner = identityKeyFromSubject('user-a');
    const operationId = await b.legacyPalm('user-a', 'old-palm-00009', false);
    const app = await b.app(true);
    const status = await app.inject({ method: 'GET', url: `/v1/reading-operations/${operationId}`, headers: b.headers() });
    expect(status.statusCode).toBe(200);
    const retry = await app.inject({
      method: 'POST', url: '/v1/reading-operations', headers: b.headers(),
      payload: { readingType: 'palm', sourceRequestId: 'old-palm-00009' },
    });
    expect(retry.statusCode).toBe(200);
    expect(retry.json().data.operationId).toBe(operationId);
    b.clock.ms = NOW + WAIT.palm + 1;
    const claim = await app.inject({
      method: 'POST', url: `/v1/reading-operations/${operationId}/claim`, headers: b.headers(), payload: {},
    });
    expect(claim.json().data.execute).toBe(true);
    expect((await b.flow.failFinal({ ownerUserId: owner, operationId, failureCode: 'unavailable' })).status).toBe('failed');
    await app.close();
  });

  it('a Palm reading delivered before the rollout replays for the same key', async () => {
    const b = backend();
    const owner = identityKeyFromSubject('user-a');
    const admitted = await admitRitualQuota({
      config: testConfig(), store: b.store, clock: b.clock, operation: 'palm_analysis',
      identity: owner, idempotencyKey: 'delivered-palm-01',
    });
    if (admitted.action !== 'hold') throw new Error('setup');
    const body = { success: true, data: { overall: 'eski el falı' } };
    await finishRitualQuota(b.store, owner, admitted.hold, body);
    const app = await b.app(true);
    const res = await app.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: b.headers('user-a', { 'idempotency-key': 'delivered-palm-01' }),
      payload: palmBody(),
    });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual(body);
    expect(b.provider.calls).toBe(0);
    await app.close();
  });
});

describe('unchanged paths', () => {
  it('commerce off: a direct palm photo reaches the provider and Palm creates wait, as before',
    async () => {
      const b = backend();
      const app = await b.app(false);
      await app.inject({
        method: 'POST', url: '/v1/ai/complete',
        headers: b.headers('user-a', { 'idempotency-key': 'off-palm-00001' }),
        payload: palmBody(),
      });
      expect(b.provider.calls).toBeGreaterThan(0);
      const created = await app.inject({
        method: 'POST', url: '/v1/reading-operations', headers: b.headers(),
        payload: { readingType: 'palm', sourceRequestId: 'off-palm-create-1' },
      });
      expect(created.json().data.remainingMs).toBe(WAIT.palm);
      await app.close();
    });

  it('commerce off: a claimed operation is not pinned to one key (no new state written)', async () => {
    const b = backend();
    const operationId = await b.legacyPalm();
    const app = await b.app(false);
    await staged(app, b.headers('user-a', { 'idempotency-key': 'off-key-one-01' }), operationId);
    const second = await staged(app, b.headers('user-a', { 'idempotency-key': 'off-key-two-01' }), operationId);
    expect(second.json().error?.code).not.toBe(DENIED);
    expect(b.count('readingLegacyDirectAi')).toBe(0);
    await app.close();
  });

  it('commerce on: non-reading AI (chat) still reaches the provider; paid Coffee V3 still opens',
    async () => {
      const b = backend();
      await b.buy('user-a', 'app.oracly.reading.coffee');
      const app = await b.app(true);
      await app.inject({
        method: 'POST', url: '/v1/ai/complete',
        headers: b.headers('user-a', { 'idempotency-key': 'chat-on-000001' }),
        payload: chatBody,
      });
      expect(b.provider.calls).toBeGreaterThan(0);
      const v3 = await app.inject({
        method: 'POST', url: '/v1/reading-operations', headers: b.headers(),
        payload: {
          readingType: 'coffee', language: 'tr', sourceRequestId: 'paid-v3-000001',
          coffeeInputContract: 'trusted_intention_v1', intention: INTENTION, coffeeCaptureContract: 'three_view_v3',
        },
      });
      expect(v3.statusCode).toBe(200);
      expect(v3.json().data.remainingMs).toBe(0);
      await app.close();
    });
});
