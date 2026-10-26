/**
 * With reading commerce on, a NEW Coffee reading exists only through a
 * server-owned credit (Coffee V3, three_view_v3). Older clients — the
 * unslotted legacy create, Coffee V2 (trusted_intention_v1 without a capture
 * contract) and the synchronous `/v1/ai/complete` coffee_analysis — cannot
 * start a free one. Operations created before the rollout keep working:
 * status, an owner-matched idempotent create retry, claim/complete/fail and
 * a fulfilment call for an operation the caller has already claimed.
 * With commerce off nothing changes.
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
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../src/reading/operation-staged-image-service.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
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
  coffeeBody,
  fakeJpeg,
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

const LEGACY = { readingType: 'coffee' } as const;
const V2 = {
  readingType: 'coffee', language: 'tr',
  coffeeInputContract: 'trusted_intention_v1', intention: INTENTION,
} as const;
const V3 = { ...V2, coffeeCaptureContract: 'three_view_v3' } as const;

/** One shared backend state; an app per rollout state (commerce off / on). */
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

  async function app(commerce: boolean) {
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
      ritualQuotaStore: store,
      readingStagedImages: stagedImages,
    });
  }

  /** The one unslotted photo a legacy Coffee operation carries. */
  async function stageLegacy(operationId: string, sub = 'user-a') {
    await stagedImages.stage({
      ownerUserId: identityKeyFromSubject(sub), operationId, mimeType: 'image/jpeg',
      imageBase64: fakeJpeg(12_000).toString('base64'),
    });
  }

  const headers = (sub = 'user-a', extra: Record<string, string> = {}) => ({
    ...authHeader(signHs256(SECRET, { sub })),
    ...appCheckHeader('good-token'),
    ...extra,
  });

  const count = (prefix: string) =>
    [...store.docs.keys()].filter((key) => key.startsWith(`${prefix}/`)).length;

  return { store, clock, repository, operations, entitlements, gems, flow, provider, app, headers, count, stageLegacy };
}

type Backend = ReturnType<typeof backend>;
type App = Awaited<ReturnType<Backend['app']>>;

function create(app: App, headers: Record<string, string>, body: Record<string, unknown>) {
  return app.inject({ method: 'POST', url: '/v1/reading-operations', headers, payload: body });
}

async function nothingCreated(b: Backend) {
  expect(b.count('readingOperations')).toBe(0);
  expect(b.count('readingOperationKeys')).toBe(0);
}

describe('commerce on: no new free Coffee through /v1/reading-operations', () => {
  for (const [label, body] of [
    ['legacy unslotted (no contract)', LEGACY],
    ['legacy with language only', { ...LEGACY, language: 'tr' }],
    ['Coffee V2 trusted_intention_v1 without a capture contract', V2],
  ] as const) {
    it(`${label}: 403 reading_entitlement_required, nothing stored, no credit or gem touched`,
      async () => {
        const b = backend();
        const owner = identityKeyFromSubject('user-a');
        await b.entitlements.grantPurchase({
          ownerUserId: owner, platform: 'android', appId: 'app.oracly',
          productId: 'app.oracly.reading.coffee', purchaseToken: 'tok-1', transactionId: 'GPA.1', atMs: NOW,
        });
        await b.gems.credit({ ownerUserId: owner, amount: 25, idempotencyKey: 'seed-gems-01' });
        const app = await b.app(true);
        const res = await create(app, b.headers(), { ...body, sourceRequestId: 'new-coffee-0001' });
        expect(res.statusCode).toBe(403);
        expect(res.json()).toMatchObject({ success: false, error: { code: 'reading_entitlement_required' } });
        await nothingCreated(b);
        expect((await b.entitlements.balance(owner)).coffee).toBe(1); // never silently spent
        expect(await b.gems.balanceOf(owner)).toBe(25);
        expect(b.provider.calls).toBe(0);
        await app.close();
      });
  }

  it('client payment claims do not unlock it (unknown fields ignored, price fields refused)',
    async () => {
      const b = backend();
      const app = await b.app(true);
      const ignored = await create(app, b.headers(), {
        ...LEGACY, sourceRequestId: 'fake-paid-0001', paid: true, entitlement: 'coffee', purchaseToken: 'x',
      });
      expect(ignored.statusCode).toBe(403);
      for (const key of ['price', 'grants', 'amount']) {
        const refused = await create(app, b.headers(), { ...V2, sourceRequestId: `fake-${key}-01`, [key]: 1 });
        expect(refused.statusCode).toBe(400);
      }
      await nothingCreated(b);
      await app.close();
    });

  it('retired or forged capture contracts are refused, never downgraded to a free create',
    async () => {
      const b = backend();
      const app = await b.app(true);
      for (const capture of ['four_view_v3', 'three_view_v2', '', null]) {
        const res = await create(app, b.headers(), { ...V2, sourceRequestId: 'forged-cap-01', coffeeCaptureContract: capture });
        expect(res.statusCode).toBe(400);
      }
      // V3 capture without the intention contract (V3 shape tampered).
      const tampered = await create(app, b.headers(), {
        readingType: 'coffee', language: 'tr', sourceRequestId: 'forged-cap-02', coffeeCaptureContract: 'three_view_v3',
      });
      expect(tampered.statusCode).toBe(400);
      await nothingCreated(b);
      await app.close();
    });

  it('parallel attempts (same and different source) create nothing', async () => {
    const b = backend();
    const app = await b.app(true);
    const results = await Promise.all([
      ...Array.from({ length: 4 }, () => create(app, b.headers(), { ...LEGACY, sourceRequestId: 'same-src-0001' })),
      ...Array.from({ length: 4 }, (_, i) => create(app, b.headers(), { ...V2, sourceRequestId: `par-src-000${i}` })),
    ]);
    expect(results.map((r) => r.statusCode)).toEqual(Array(8).fill(403));
    await nothingCreated(b);
    await app.close();
  });
});

describe('commerce on: operations created before the rollout keep working', () => {
  async function seededLegacy(body: Record<string, unknown> = LEGACY, sub = 'user-a') {
    const b = backend();
    const before = await b.app(false);
    const made = await create(before, b.headers(sub), { ...body, sourceRequestId: 'old-coffee-0001' });
    expect(made.statusCode).toBe(200);
    await before.close();
    return { b, operationId: made.json().data.operationId as string };
  }

  for (const [label, body] of [['legacy', LEGACY], ['Coffee V2', V2]] as const) {
    it(`${label}: the same create retry returns the same operation, creates nothing new`,
      async () => {
        const { b, operationId } = await seededLegacy(body);
        const after = await b.app(true);
        const opsBefore = b.count('readingOperations');
        const results = await Promise.all([1, 2, 3].map(() =>
          create(after, b.headers(), { ...body, sourceRequestId: 'old-coffee-0001' })));
        for (const res of results) {
          expect(res.statusCode).toBe(200);
          expect(res.json().data.operationId).toBe(operationId);
          expect(res.json().data.status).toBe('waiting');
        }
        expect(b.count('readingOperations')).toBe(opsBefore);
        await after.close();
      });
  }

  it('a retry with a changed contract is refused and creates nothing', async () => {
    const { b } = await seededLegacy(LEGACY);
    const after = await b.app(true);
    const res = await create(after, b.headers(), { ...V2, sourceRequestId: 'old-coffee-0001' });
    expect(res.statusCode).toBe(400);
    expect(b.count('readingOperations')).toBe(1);
    await after.close();
  });

  it("another account reusing the source id gets nothing (no access to the owner's operation)",
    async () => {
      const { b, operationId } = await seededLegacy(LEGACY);
      const after = await b.app(true);
      const res = await create(after, b.headers('user-b'), { ...LEGACY, sourceRequestId: 'old-coffee-0001' });
      expect(res.statusCode).toBe(403);
      expect(JSON.stringify(res.json())).not.toContain(operationId);
      const peek = await after.inject({ method: 'GET', url: `/v1/reading-operations/${operationId}`, headers: b.headers('user-b') });
      expect(peek.statusCode).toBe(404);
      expect(b.count('readingOperations')).toBe(1);
      await after.close();
    });

  it('an expired idempotency key does not open a new free operation', async () => {
    const { b } = await seededLegacy(LEGACY);
    for (const key of [...b.store.docs.keys()].filter((k) => k.startsWith('readingOperationKeys/'))) {
      b.store.docs.delete(key); // Firestore TTL removed it
    }
    const after = await b.app(true);
    const res = await create(after, b.headers(), { ...LEGACY, sourceRequestId: 'old-coffee-0001' });
    expect(res.statusCode).toBe(403);
    expect(b.count('readingOperations')).toBe(1);
    await after.close();
  });

  it('status, claim, complete and fail still work for the old operation', async () => {
    const { b, operationId } = await seededLegacy(LEGACY);
    const owner = identityKeyFromSubject('user-a');
    const after = await b.app(true);
    await b.stageLegacy(operationId);
    const status = await after.inject({ method: 'GET', url: `/v1/reading-operations/${operationId}`, headers: b.headers() });
    expect(status.statusCode).toBe(200);
    expect(status.json().data.operationId).toBe(operationId);
    b.clock.ms += WAIT.coffee + 1;
    const claim = await after.inject({
      method: 'POST', url: `/v1/reading-operations/${operationId}/claim`, headers: b.headers(), payload: {},
    });
    expect(claim.statusCode).toBe(200);
    expect(claim.json().data.execute).toBe(true);
    const failed = await b.flow.failFinal({ ownerUserId: owner, operationId, failureCode: 'unavailable' });
    expect(failed.status).toBe('failed');
    await after.close();
  });
});

describe('commerce on: /v1/ai/complete cannot start a free Coffee', () => {
  it('an inline-image coffee_analysis is refused before the provider and keeps the free slot',
    async () => {
      const b = backend();
      const app = await b.app(true);
      const res = await app.inject({
        method: 'POST', url: '/v1/ai/complete',
        headers: b.headers('user-a', { 'idempotency-key': 'inline-coffee-0001' }),
        payload: coffeeBody(),
      });
      expect(res.statusCode).toBe(403);
      expect(res.json().error.code).toBe('reading_entitlement_required');
      expect(b.provider.calls).toBe(0);
      const slot = await admitRitualQuota({
        config: testConfig(), store: b.store, clock: b.clock, operation: 'coffee_analysis',
        identity: identityKeyFromSubject('user-a'), idempotencyKey: 'probe-slot-0001',
      });
      expect(slot.action).toBe('hold');
      await app.close();
    });

  it('a staged call for an operation that is not claimed (waiting), another account\'s, '
    + 'or a missing one is refused', async () => {
    const b = backend();
    const before = await b.app(false);
    const legacy = (await create(before, b.headers(), { ...LEGACY, sourceRequestId: 'old-coffee-0002' })).json().data.operationId;
    await b.stageLegacy(legacy);
    await before.close();
    const app = await b.app(true);
    const staged = (operationId: string, sub = 'user-a', key = `staged-${sub}-01`) => app.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: b.headers(sub, { 'idempotency-key': key }),
      payload: { operation: 'coffee_analysis', payload: { mimeType: 'image/jpeg', operationId } },
    });
    expect((await staged(legacy)).json().error.code).toBe('reading_entitlement_required'); // waiting
    expect((await staged(legacy, 'user-b')).json().error.code).toBe('reading_entitlement_required');
    expect((await staged('0123456789abcdef0123456789abcdef', 'user-a', 'staged-missing-01')).json().error.code)
      .toBe('reading_entitlement_required');
    expect(b.provider.calls).toBe(0);
    await app.close();
  });

  it('an old operation the caller has claimed can still be fulfilled', async () => {
    const b = backend();
    const owner = identityKeyFromSubject('user-a');
    const before = await b.app(false);
    const operationId = (await create(before, b.headers(), { ...LEGACY, sourceRequestId: 'old-coffee-0003' })).json().data.operationId;
    await b.stageLegacy(operationId);
    await before.close();
    b.clock.ms += WAIT.coffee + 1;
    expect((await b.flow.claim(owner, operationId)).execute).toBe(true);
    const app = await b.app(true);
    const res = await app.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: b.headers('user-a', { 'idempotency-key': 'claimed-coffee-01' }),
      payload: { operation: 'coffee_analysis', payload: { mimeType: 'image/jpeg', operationId } },
    });
    expect(res.json().error?.code).not.toBe('reading_entitlement_required');
    expect(b.provider.calls).toBeGreaterThan(0); // reached the (fake) provider
    await app.close();
  });

  it("another account cannot fulfil the owner's claimed operation", async () => {
    const b = backend();
    const owner = identityKeyFromSubject('user-a');
    const before = await b.app(false);
    const operationId = (await create(before, b.headers(), { ...LEGACY, sourceRequestId: 'old-coffee-0004' })).json().data.operationId;
    await b.stageLegacy(operationId);
    await before.close();
    b.clock.ms += WAIT.coffee + 1;
    expect((await b.flow.claim(owner, operationId)).execute).toBe(true);
    const app = await b.app(true);
    const res = await app.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: b.headers('user-b', { 'idempotency-key': 'foreign-claim-01' }),
      payload: { operation: 'coffee_analysis', payload: { mimeType: 'image/jpeg', operationId } },
    });
    expect(res.json().error.code).toBe('reading_entitlement_required');
    expect(b.provider.calls).toBe(0);
    await app.close();
  });

  it('a claimed Palm operation cannot be read as a coffee_analysis', async () => {
    const b = backend();
    const owner = identityKeyFromSubject('user-a');
    const before = await b.app(false);
    const operationId = (await create(before, b.headers(), { readingType: 'palm', sourceRequestId: 'old-palm-00001' })).json().data.operationId;
    await before.close();
    b.clock.ms += WAIT.palm + 1;
    expect((await b.flow.claim(owner, operationId)).execute).toBe(true);
    const app = await b.app(true);
    const res = await app.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: b.headers('user-a', { 'idempotency-key': 'palm-as-coffee-01' }),
      payload: { operation: 'coffee_analysis', payload: { mimeType: 'image/jpeg', operationId } },
    });
    expect(res.json().error.code).toBe('reading_entitlement_required');
    await app.close();
  });

  it('a claimed paid Coffee V3 operation is never fulfilled through /v1/ai/complete', async () => {
    const b = backend();
    const owner = identityKeyFromSubject('user-a');
    await b.entitlements.grantPurchase({
      ownerUserId: owner, platform: 'android', appId: 'app.oracly',
      productId: 'app.oracly.reading.coffee', purchaseToken: 'tok-v3', transactionId: 'GPA.v3', atMs: NOW,
    });
    const app = await b.app(true);
    const operationId = (await create(app, b.headers(), { ...V3, sourceRequestId: 'paid-v3-claim-01' })).json().data.operationId;
    expect((await b.flow.claim(owner, operationId)).execute).toBe(true);
    const res = await app.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: b.headers('user-a', { 'idempotency-key': 'v3-via-ai-0001' }),
      payload: { operation: 'coffee_analysis', payload: { mimeType: 'image/jpeg', operationId } },
    });
    expect(res.json().error.code).toBe('reading_entitlement_required');
    expect(b.provider.calls).toBe(0);
    await app.close();
  });

  it('a reading delivered before the rollout still replays for the same key', async () => {
    const b = backend();
    const owner = identityKeyFromSubject('user-a');
    const admitted = await admitRitualQuota({
      config: testConfig(), store: b.store, clock: b.clock, operation: 'coffee_analysis',
      identity: owner, idempotencyKey: 'delivered-coffee-01',
    });
    if (admitted.action !== 'hold') throw new Error('setup');
    const body = { success: true, data: { overall: 'eski fal' } };
    await finishRitualQuota(b.store, owner, admitted.hold, body);
    const app = await b.app(true);
    const res = await app.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: b.headers('user-a', { 'idempotency-key': 'delivered-coffee-01' }),
      payload: coffeeBody(),
    });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual(body);
    expect(b.provider.calls).toBe(0);
    await app.close();
  });
});

describe('unchanged paths', () => {
  it('commerce off: legacy and V2 Coffee create as before, with the wait', async () => {
    const b = backend();
    const app = await b.app(false);
    for (const [i, body] of [LEGACY, V2].entries()) {
      const res = await create(app, b.headers(), { ...body, sourceRequestId: `off-coffee-000${i}` });
      expect(res.statusCode).toBe(200);
      expect(res.json().data.remainingMs).toBe(WAIT.coffee);
    }
    await app.close();
  });

  it('commerce off: inline coffee_analysis reaches the provider as before', async () => {
    const b = backend();
    const app = await b.app(false);
    await app.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: b.headers('user-a', { 'idempotency-key': 'off-inline-0001' }),
      payload: coffeeBody(),
    });
    expect(b.provider.calls).toBeGreaterThan(0);
    await app.close();
  });

  it('commerce on: paid Coffee V3 and Palm still open at once with one credit; Soulmate unchanged',
    async () => {
      const b = backend();
      const owner = identityKeyFromSubject('user-a');
      for (const [i, productId] of (['app.oracly.reading.coffee', 'app.oracly.reading.palm'] as const).entries()) {
        await b.entitlements.grantPurchase({
          ownerUserId: owner, platform: 'android', appId: 'app.oracly', productId,
          purchaseToken: `tok-${i}`, transactionId: `GPA.${i}`, atMs: NOW,
        });
      }
      const app = await b.app(true);
      const v3 = await create(app, b.headers(), { ...V3, sourceRequestId: 'paid-v3-00001' });
      expect(v3.statusCode).toBe(200);
      expect(v3.json().data.remainingMs).toBe(0);
      const palm = await create(app, b.headers(), { readingType: 'palm', sourceRequestId: 'paid-palm-0001' });
      expect(palm.statusCode).toBe(200);
      expect(palm.json().data.remainingMs).toBe(0);
      expect(await b.entitlements.balance(owner)).toMatchObject({ coffee: 0, palm: 0 });
      const soulmate = await create(app, b.headers(), { readingType: 'soulmate', sourceRequestId: 'soulmate-00001' });
      expect(soulmate.statusCode).toBe(200);
      await app.close();
    });
});
