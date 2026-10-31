/**
 * Freemium V1 (dark): free Coffee 1 + Palm 1 a day, Premium 2 + 2 in total
 * and instant, then an existing reading credit. The slot is reserved at
 * create on the ritual counter the worker charges, so a reading is charged
 * once; a failed reading keeps no slot. Free use sits under 30% of the
 * day's AI ceiling. Flag off: every existing behaviour is unchanged.
 *
 * Real ReadingProcessor, routes, ritual quota and entitlement ledger over
 * the in-memory store; the provider is a counting fake (no real AI).
 */
import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { loadConfig } from '../src/config.js';
import { ErrorCode, ProxyError } from '../src/errors.js';
import { CoffeeV3TerminalFailure } from '../src/ai/reading/coffee-v3-live-pipeline.js';
import type { SpendGuard } from '../src/ai/spend-guard.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../src/reading/operation-staged-image-service.js';
import {
  FREEMIUM_ACCESS,
  FREEMIUM_SPEND_DAYS,
  freeSpendCapMicros,
  openFreemiumCreate,
} from '../src/reading/freemium-access.js';
import { FreemiumSpendGuard, withFreemiumSpend } from '../src/reading/freemium-spend.js';
import { ReadingEntitlementLedger } from '../src/reading/reading-entitlement-ledger.js';
import { ReadingFlow } from '../src/reading/reading-flow.js';
import { ReadingProcessor } from '../src/reading/reading-processor.js';
import { ReadingResultRepository } from '../src/reading/reading-result-repository.js';
import { ACCOUNT_DELETION_RECEIPTS, AccountDeletedError, accountDeletionReceiptId } from '../src/account/deletion-barrier.js';
import {
  docId,
  RITUAL_COUNTERS,
  RITUAL_DAILY_LIMIT,
  ritualDailyLimit,
} from '../src/reading/ritual-daily-quota.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import type { ServerClock } from '../src/reading/clock.js';
import {
  StaticAppCheckVerifier,
  appCheckHeader,
  authHeader,
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
const NOW = Date.parse('2026-10-31T09:00:00.000Z');
const DAY = '2026-10-31';
const HOUR = 60 * 60 * 1000;
const INTENTION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';
const V3_SLOTS = ['v3_cup_view_a', 'v3_cup_view_b', 'v3_saucer_view'] as const;
const WAIT = { coffee: 2 * HOUR, palm: 4 * HOUR, soulmate: 1000 };
let seq = 0;

type Kind = 'coffee' | 'palm';

function body(readingType: Kind, sourceRequestId: string) {
  return readingType === 'palm'
    ? { readingType, sourceRequestId, language: 'tr' as const }
    : {
        readingType,
        sourceRequestId,
        language: 'tr' as const,
        coffeeIntention: INTENTION,
        coffeeInputContract: 'trusted_intention_v1' as const,
        coffeeCaptureContract: 'three_view_v3' as const,
      };
}

function freemiumEnv(extra: Record<string, string> = {}) {
  return {
    READING_STAGING_BUCKET: 'test-bucket',
    ORACLY_COFFEE_V3_ENABLED: 'true',
    ORACLY_FREEMIUM_V1_ENABLED: 'true',
    OPENAI_API_KEY: 'sk-test-not-real',
    OPENAI_VISION: 'true',
    AI_DAILY_SPEND_CAP_USD: '5',
    ...extra,
  };
}

/** Real worker over the in-memory store; the provider is a counting fake. */
function world(env: Record<string, string> = freemiumEnv(), outcome: 'fail' | 'palm_ok' = 'fail') {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(NOW);
  const config = testConfig(env);
  const repository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(repository, clock, provisionalWaitPolicy(WAIT));
  const entitlements = new ReadingEntitlementLedger(store);
  const stagedImages = new ReadingStagedImageService(
    new FirestoreReadingStagedImageRepository(store),
    new MemoryStagedObjectStore(),
    operations,
    clock,
    config,
  );
  const premiumOwners = new Set<string>();
  const premium = { isPremiumActive: async (owner: string) => premiumOwners.has(owner) };
  const calls = { coffeeV3: 0, handle: 0 };
  const flow = new ReadingFlow(store, clock, operations, new GemLedger(store, clock, provisionalGemCostPolicy()), entitlements);
  const processor = new ReadingProcessor(
    repository,
    flow,
    new FirestoreReadingStagedImageRepository(store),
    stagedImages,
    new ReadingResultRepository(store),
    {
      async handle() {
        calls.handle += 1;
        if (outcome === 'palm_ok') {
          return {
            overall: 'synthetic palm result',
            lifeLine: 'synthetic life',
            headLine: 'synthetic head',
            heartLine: 'synthetic heart',
            fateLine: '',
            takeaway: 'synthetic takeaway',
          };
        }
        throw new ProxyError(ErrorCode.spendGuard, 503);
      },
      async coffeeV3() {
        calls.coffeeV3 += 1;
        throw new CoffeeV3TerminalFailure('unavailable', 'test_provider_end');
      },
    },
    clock,
    undefined,
    false,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    { config, store },
  );

  async function create(owner: string, readingType: Kind, sourceRequestId = `src-${++seq}`) {
    return openFreemiumCreate({
      config, store, service: operations, premium, ownerUserId: owner, nowMs: clock.ms,
      body: body(readingType, sourceRequestId),
    });
  }

  async function stage(owner: string, operationId: string, readingType: Kind) {
    if (readingType === 'palm') {
      await stagedImages.stage({
        ownerUserId: owner, operationId, mimeType: 'image/jpeg',
        imageBase64: fakeJpeg(12_000).toString('base64'), handSide: 'right',
      });
      return;
    }
    let n = 0;
    for (const slot of V3_SLOTS) {
      n += 1;
      await stagedImages.stage({
        ownerUserId: owner, operationId, mimeType: 'image/jpeg',
        imageBase64: fakeJpeg(12_000 + n).toString('base64'), slot,
      });
    }
  }

  async function buy(owner: string, productId: string) {
    seq += 1;
    await entitlements.grantPurchase({
      ownerUserId: owner, platform: 'android', appId: 'app.oracly', productId: productId as never,
      purchaseToken: `token-${seq}`, transactionId: `GPA.${seq}`, atMs: clock.ms,
    });
  }

  function counter(owner: string, kind: Kind, day = DAY) {
    return store.docs.get(`${RITUAL_COUNTERS}/${docId(`${owner}\0${day}\0${kind}`)}`) as
      | { count: number; charges: Record<string, { state: string; live: number }> }
      | undefined;
  }

  return {
    store, clock, config, operations, entitlements, processor, calls, flow, premiumOwners,
    create, stage, buy, counter,
    balance: (owner: string) => entitlements.balance(owner),
  };
}

function recordOf(outcome: Awaited<ReturnType<typeof openFreemiumCreate>>) {
  if (outcome.kind !== 'record') throw new Error(`expected a record, got ${outcome.kind}:${outcome.code}`);
  return outcome.record;
}

describe('Freemium V1 stays dark', () => {
  it('defaults off everywhere and the deploy script never turns it on', () => {
    expect(testConfig().freemiumV1Enabled).toBe(false);
    expect(loadConfig({ APP_ENV: 'production', OPENAI_API_KEY: 'sk-test' }).freemiumV1Enabled).toBe(false);
    expect(loadConfig({ APP_ENV: 'production', OPENAI_API_KEY: 'sk-test', ORACLY_FREEMIUM_V1_ENABLED: 'yes please' })
      .freemiumV1Enabled).toBe(false);
    const script = readFileSync(new URL('../scripts/deploy-cloud-run.sh', import.meta.url), 'utf8');
    expect(script.includes('ORACLY_FREEMIUM_V1_ENABLED')).toBe(false);
  });

  it('off: the daily table, the spend guard object and the palm route are unchanged', async () => {
    const off = testConfig();
    expect(RITUAL_DAILY_LIMIT).toEqual({ coffee: 1, palm: 2, dream: 3, astrology: 2 });
    expect(ritualDailyLimit('palm', off)).toBe(2);
    expect(ritualDailyLimit('coffee', off)).toBe(1);
    const base: SpendGuard = { async reserve() {}, async settle() {} };
    expect(withFreemiumSpend(off, base, new MemoryDocumentStore(), () => new Date())).toBe(base);
    expect(withFreemiumSpend(off, null, new MemoryDocumentStore(), () => new Date())).toBeNull();

    const store = new MemoryDocumentStore();
    const clock = new FixedClock(NOW);
    const repository = new FirestoreReadingOperationRepository(store);
    const app = await testApp(testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' }), undefined, {
      appCheck: new StaticAppCheckVerifier('good-token'),
      readingOperationRepository: repository,
      readingClock: clock,
      readingWaitPolicy: provisionalWaitPolicy(WAIT),
      gemStore: store,
      soulmateEntitlement: { isPremiumActive: async () => true },
    });
    const headers = { ...authHeader(signHs256(SECRET, { sub: 'user-off' })), ...appCheckHeader('good-token') };
    for (const id of ['palm-off-1', 'palm-off-2', 'palm-off-3']) {
      const created = await app.inject({
        method: 'POST', url: '/v1/reading-operations', headers,
        payload: { readingType: 'palm', sourceRequestId: id },
      });
      expect(created.statusCode).toBe(200);
      // Premium is not consulted, the wait stays, and nothing is reserved.
      expect(created.json().data.remainingMs).toBe(4 * HOUR);
    }
    expect([...store.docs.keys()].some((key) => key.startsWith(`${FREEMIUM_ACCESS}/`))).toBe(false);
    expect([...store.docs.keys()].some((key) => key.startsWith(`${RITUAL_COUNTERS}/`))).toBe(false);
    await app.close();
  });

  it('on: Palm drops to one free reading a day', () => {
    const on = testConfig(freemiumEnv());
    expect(on.freemiumV1Enabled).toBe(true);
    expect(ritualDailyLimit('palm', on)).toBe(1);
    expect(ritualDailyLimit('coffee', on)).toBe(1);
    expect(ritualDailyLimit('dream', on)).toBe(3);
  });
});

describe('Freemium V1 access order', () => {
  it('free: Coffee 1 and Palm 1 a day, each waiting, then the day quota (no purchase prompt)', async () => {
    const w = world();
    const owner = identityKeyFromSubject('free-user');
    const coffee = recordOf(await w.create(owner, 'coffee'));
    expect(coffee.readyAtMs - coffee.createdAtMs).toBe(2 * HOUR);
    const palm = recordOf(await w.create(owner, 'palm'));
    expect(palm.readyAtMs - palm.createdAtMs).toBe(4 * HOUR);
    expect(await w.create(owner, 'coffee')).toEqual({ kind: 'error', httpStatus: 429, code: ErrorCode.coffeeDailyQuota });
    expect(await w.create(owner, 'palm')).toEqual({ kind: 'error', httpStatus: 429, code: ErrorCode.palmDailyQuota });
    expect(w.counter(owner, 'coffee')?.count).toBe(1);
    expect(w.counter(owner, 'palm')?.count).toBe(1);
    // The next UTC day opens one more each.
    w.clock.ms += 24 * HOUR;
    recordOf(await w.create(owner, 'coffee'));
    recordOf(await w.create(owner, 'palm'));
  });

  it('Premium: 2 + 2 in total a day, instant, from the server snapshot only', async () => {
    const w = world();
    const owner = identityKeyFromSubject('premium-user');
    w.premiumOwners.add(owner);
    for (const kind of ['coffee', 'palm'] as const) {
      for (let i = 0; i < 2; i++) {
        const record = recordOf(await w.create(owner, kind));
        expect(record.readyAtMs).toBe(record.createdAtMs);
      }
      const third = await w.create(owner, kind);
      expect(third.kind).toBe('error');
      expect(w.counter(owner, kind)?.count).toBe(2); // a total of 2, not 1 + 2
    }
    // Without the server snapshot the same user is a free user.
    const other = identityKeyFromSubject('claims-premium');
    recordOf(await w.create(other, 'coffee'));
    expect((await w.create(other, 'coffee')).kind).toBe('error');
  });

  it('a free slot is used before any credit; the credit only after the day is used', async () => {
    const w = world();
    const owner = identityKeyFromSubject('credit-user');
    await w.buy(owner, 'app.oracly.reading.coffee');
    expect((await w.balance(owner)).coffee).toBe(1);
    const free = recordOf(await w.create(owner, 'coffee'));
    expect((await w.balance(owner)).coffee).toBe(1);
    expect(free.readyAtMs - free.createdAtMs).toBe(2 * HOUR);
    const paid = recordOf(await w.create(owner, 'coffee'));
    expect(paid.readyAtMs).toBe(paid.createdAtMs);
    expect((await w.balance(owner)).coffee).toBe(0);
    expect(w.counter(owner, 'coffee')?.count).toBe(1); // the credit took no slot
    expect(w.store.docs.get(`${FREEMIUM_ACCESS}/${paid.operationId}`)).toMatchObject({ tier: 'credit' });
    expect(await w.create(owner, 'coffee')).toEqual({ kind: 'error', httpStatus: 429, code: ErrorCode.coffeeDailyQuota });
    expect((await w.balance(owner)).coffee).toBe(0);
  });

  it('a retry of the same create is the same reading: no second slot, no credit', async () => {
    const w = world();
    const owner = identityKeyFromSubject('retry-user');
    await w.buy(owner, 'app.oracly.reading.palm');
    const first = recordOf(await w.create(owner, 'palm', 'same-palm-create'));
    const again = recordOf(await w.create(owner, 'palm', 'same-palm-create'));
    expect(again.operationId).toBe(first.operationId);
    expect(w.counter(owner, 'palm')?.count).toBe(1);
    expect((await w.balance(owner)).palm).toBe(1);
  });

  it('two concurrent creates cannot both take the one free slot', async () => {
    const w = world();
    const owner = identityKeyFromSubject('race-user');
    const results = await Promise.all([
      w.create(owner, 'coffee'), w.create(owner, 'coffee'), w.create(owner, 'coffee'),
    ]);
    expect(results.filter((r) => r.kind === 'record')).toHaveLength(1);
    expect(results.filter((r) => r.kind === 'error')).toHaveLength(2);
    expect(w.counter(owner, 'coffee')?.count).toBe(1);
    // Same request raced: one reading, one slot.
    const other = identityKeyFromSubject('race-same');
    const same = await Promise.all([w.create(other, 'palm', 'race-same-id'), w.create(other, 'palm', 'race-same-id')]);
    const ids = same.map((r) => recordOf(r).operationId);
    expect(new Set(ids).size).toBe(1);
    expect(w.counter(other, 'palm')?.count).toBe(1);
  });

  it('a failed reading keeps no slot', async () => {
    const w = world();
    const owner = identityKeyFromSubject('failed-user');
    const first = recordOf(await w.create(owner, 'coffee'));
    expect((await w.create(owner, 'coffee')).kind).toBe('error');
    await w.flow.failFinal({ ownerUserId: owner, operationId: first.operationId, failureCode: 'unavailable' });
    const next = recordOf(await w.create(owner, 'coffee'));
    expect(next.operationId).not.toBe(first.operationId);
    expect(w.counter(owner, 'coffee')?.count).toBe(1);
  });

  it('a deleted account opens nothing', async () => {
    const w = world();
    const owner = identityKeyFromSubject('deleted-user');
    w.store.docs.set(`${ACCOUNT_DELETION_RECEIPTS}/${accountDeletionReceiptId(owner)}`, { state: 'started' });
    await expect(w.create(owner, 'coffee')).rejects.toBeInstanceOf(AccountDeletedError);
    expect(w.counter(owner, 'coffee')).toBeUndefined();
  });
});

describe('Freemium V1 with the real worker', () => {
  it('the worker charges the reserved slot once; a provider failure returns it', async () => {
    const w = world();
    const owner = identityKeyFromSubject('worker-fail');
    const op = recordOf(await w.create(owner, 'palm'));
    await w.stage(owner, op.operationId, 'palm');
    w.clock.ms += 4 * HOUR;
    await Promise.allSettled([w.processor.process(op.operationId), w.processor.process(op.operationId)]);
    expect(w.calls.handle).toBe(1);
    expect((await w.operations.get(owner, op.operationId)).status).toBe('failed');
    expect(w.counter(owner, 'palm')?.count ?? 0).toBe(0); // refunded by the existing settle
    recordOf(await w.create(owner, 'palm')); // the day's slot is usable again
  });

  it('a delivered reading keeps its slot; a reading made before midnight is charged on its own day', async () => {
    const w = world(freemiumEnv(), 'palm_ok');
    const owner = identityKeyFromSubject('worker-ok');
    w.clock.ms = Date.parse('2026-10-31T22:30:00.000Z');
    const op = recordOf(await w.create(owner, 'palm'));
    await w.stage(owner, op.operationId, 'palm');
    w.clock.ms += 4 * HOUR; // processed on 1 November
    await w.processor.process(op.operationId);
    expect(w.calls.handle).toBe(1);
    expect((await w.operations.get(owner, op.operationId)).status).toBe('ready');
    expect(w.counter(owner, 'palm')).toMatchObject({ count: 1 });
    expect(w.counter(owner, 'palm')?.charges[op.operationId]?.state).toBe('done');
    expect(w.counter(owner, 'palm', '2026-11-01')).toBeUndefined();
    recordOf(await w.create(owner, 'palm')); // 1 November is untouched
  });

  it('Premium Coffee V3 runs at once and a terminal failure gives the slot back', async () => {
    const w = world();
    const owner = identityKeyFromSubject('worker-premium');
    w.premiumOwners.add(owner);
    const op = recordOf(await w.create(owner, 'coffee'));
    await w.stage(owner, op.operationId, 'coffee');
    await w.processor.process(op.operationId);
    expect(w.calls.coffeeV3).toBe(1);
    expect((await w.operations.get(owner, op.operationId)).status).toBe('failed');
    expect(w.counter(owner, 'coffee')?.count ?? 0).toBe(0);
  });

  it('a credit reading is not charged on the day counter and is refunded once', async () => {
    const w = world();
    const owner = identityKeyFromSubject('worker-credit');
    await w.buy(owner, 'app.oracly.reading.coffee');
    recordOf(await w.create(owner, 'coffee')); // the free slot
    const paid = recordOf(await w.create(owner, 'coffee'));
    await w.stage(owner, paid.operationId, 'coffee');
    await w.processor.process(paid.operationId);
    expect(w.calls.coffeeV3).toBe(1);
    expect(w.counter(owner, 'coffee')?.count).toBe(1);
    expect((await w.balance(owner)).coffee).toBe(1); // terminal failure: credit restored once
  });
});

describe('Freemium V1 cost protection', () => {
  it('free use is held under 30% of the day ceiling; the day guard still applies to all', async () => {
    const store = new MemoryDocumentStore();
    const config = testConfig(freemiumEnv());
    expect(freeSpendCapMicros(config)).toBe(1_500_000);
    const reserved: string[] = [];
    let baseTotal = 0;
    const base: SpendGuard = {
      async reserve(input) {
        // Like the day guard: one reservation per key.
        if (reserved.includes(input.key)) return;
        if (baseTotal + input.ceilingMicros > 5_000_000) throw new ProxyError(ErrorCode.spendGuard, 503);
        baseTotal += input.ceilingMicros;
        reserved.push(input.key);
      },
      async settle() {},
    };
    const now = () => new Date(NOW);
    const guard = withFreemiumSpend(config, base, store, now) as FreemiumSpendGuard;
    expect(guard).toBeInstanceOf(FreemiumSpendGuard);
    const access = (id: string, tier: string) =>
      store.docs.set(`${FREEMIUM_ACCESS}/${id}`, { ownerUserId: 'o', kind: 'coffee', tier, day: DAY });
    const free1 = 'a'.repeat(32); const free2 = 'b'.repeat(32); const prem = 'c'.repeat(32);
    access(free1, 'free'); access(free2, 'free'); access(prem, 'premium');

    await guard.reserve({ key: `reading-operation:${free1}:coffee-v3:model`, ceilingMicros: 1_000_000 });
    await expect(guard.reserve({ key: `reading-operation:${free2}:coffee-v3:model`, ceilingMicros: 600_000 }))
      .rejects.toMatchObject({ code: ErrorCode.spendGuard });
    expect(reserved).toHaveLength(1); // refused before the day guard and the provider
    // Premium is outside the free share but inside the day ceiling.
    await guard.reserve({ key: `reading-operation:${prem}:coffee-v3:model`, ceilingMicros: 2_500_000 });
    await expect(guard.reserve({ key: `reading-operation:${prem}:palm`, ceilingMicros: 1_600_000 }))
      .rejects.toMatchObject({ code: ErrorCode.spendGuard });
    const day = () => store.docs.get(`${FREEMIUM_SPEND_DAYS}/${DAY}`) as Record<string, number>;
    expect(day()).toMatchObject({ freeMicros: 1_000_000, premiumMicros: 2_500_000, freeCapMicros: 1_500_000 });
    // The same key again is the same reservation.
    await guard.reserve({ key: `reading-operation:${free1}:coffee-v3:model`, ceilingMicros: 1_000_000 });
    expect(day().freeMicros).toBe(1_000_000);
    // Settled actual cost frees the share; an unknown outcome keeps the ceiling.
    await guard.settle({ key: `reading-operation:${free1}:coffee-v3:model`, actualMicros: 200_000 });
    expect(day().freeMicros).toBe(200_000);
    await guard.settle({ key: `reading-operation:${prem}:coffee-v3:model`, actualMicros: null });
    expect(day().premiumMicros).toBe(2_500_000); // the refused 1.6M was released
    await guard.reserve({ key: `reading-operation:${free2}:coffee-v3:model`, ceilingMicros: 600_000 });
    expect(day().freeMicros).toBe(800_000);
    // Anything that is not a Freemium reading goes to the day guard alone.
    await guard.reserve({ key: 'tarot_reading:xyz:tarot', ceilingMicros: 10 });
    expect(reserved.at(-1)).toBe('tarot_reading:xyz:tarot');
    expect(day().freeMicros).toBe(800_000);
  });

  it('a free create stops when the free share is used, but a credit still opens', async () => {
    const w = world();
    const owner = identityKeyFromSubject('share-user');
    w.store.docs.set(`${FREEMIUM_SPEND_DAYS}/${DAY}`, { freeMicros: 1_500_000 });
    expect(await w.create(owner, 'coffee')).toEqual({ kind: 'error', httpStatus: 503, code: ErrorCode.spendGuard });
    expect(w.counter(owner, 'coffee')).toBeUndefined();
    await w.buy(owner, 'app.oracly.reading.coffee');
    const paid = recordOf(await w.create(owner, 'coffee'));
    expect(paid.readyAtMs).toBe(paid.createdAtMs);
    // Premium is not held by the free share.
    const member = identityKeyFromSubject('share-premium');
    w.premiumOwners.add(member);
    recordOf(await w.create(member, 'coffee'));
  });

  it('missing configuration never means unlimited free use', async () => {
    expect(freeSpendCapMicros(testConfig({ ORACLY_FREEMIUM_V1_ENABLED: 'true' }))).toBe(0);
    const noCap = world(freemiumEnv({ AI_DAILY_SPEND_CAP_USD: '' }));
    const owner = identityKeyFromSubject('no-cap');
    expect(await noCap.create(owner, 'coffee')).toMatchObject({ kind: 'error', code: ErrorCode.spendGuard });
    const killed = world(freemiumEnv({ AI_SPEND_KILL_SWITCH: 'true' }));
    expect(await killed.create(owner, 'palm')).toMatchObject({ kind: 'error', code: ErrorCode.spendGuard });
    const noStore = await openFreemiumCreate({
      config: testConfig(freemiumEnv()), store: null, service: noCap.operations, premium: undefined,
      ownerUserId: owner, nowMs: NOW, body: body('coffee', 'no-store'),
    });
    expect(noStore).toMatchObject({ kind: 'error', httpStatus: 503 });
  });
});

describe('Freemium V1 through the public route', () => {
  it('routes V3 Coffee and Palm through the access order; legacy Coffee is untouched', async () => {
    const store = new MemoryDocumentStore();
    const clock = new FixedClock(NOW);
    const repository = new FirestoreReadingOperationRepository(store);
    const premiumOwners = new Set<string>();
    const app = await testApp(testConfig({ ...freemiumEnv(), AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' }), undefined, {
      appCheck: new StaticAppCheckVerifier('good-token'),
      readingOperationRepository: repository,
      readingClock: clock,
      readingWaitPolicy: provisionalWaitPolicy(WAIT),
      gemStore: store,
      soulmateEntitlement: { isPremiumActive: async (owner) => premiumOwners.has(owner) },
    });
    const headers = (sub: string) => ({ ...authHeader(signHs256(SECRET, { sub })), ...appCheckHeader('good-token') });
    const post = (sub: string, payload: Record<string, unknown>) =>
      app.inject({ method: 'POST', url: '/v1/reading-operations', headers: headers(sub), payload });
    const v3 = (id: string) => ({
      readingType: 'coffee', sourceRequestId: id, language: 'tr',
      coffeeInputContract: 'trusted_intention_v1', intention: INTENTION, coffeeCaptureContract: 'three_view_v3',
    });

    const first = await post('route-free', v3('route-v3-1'));
    expect(first.statusCode).toBe(200);
    expect(first.json().data.remainingMs).toBe(2 * HOUR);
    const second = await post('route-free', v3('route-v3-2'));
    expect(second.statusCode).toBe(429);
    expect(second.json().error.code).toBe('coffee_daily_quota');

    premiumOwners.add(identityKeyFromSubject('route-premium'));
    const instant = await post('route-premium', { readingType: 'palm', sourceRequestId: 'route-palm-1' });
    expect(instant.statusCode).toBe(200);
    expect(instant.json().data.remainingMs).toBe(0);

    // Legacy (non-V3) Coffee keeps its existing path: no Freemium reservation.
    const legacy = await post('route-legacy', { readingType: 'coffee', sourceRequestId: 'route-legacy-1' });
    expect(legacy.statusCode).toBe(200);
    expect(legacy.json().data.remainingMs).toBe(2 * HOUR);
    const owner = identityKeyFromSubject('route-legacy');
    expect(store.docs.get(`${RITUAL_COUNTERS}/${docId(`${owner}\0${DAY}\0coffee`)}`)).toBeUndefined();
    await app.close();
  });
});
