/**
 * Paid Coffee V3 / Palm readings are not limited by the free daily ritual
 * quota (product decision, #44, 27 Oct 2026). The proof of payment is the
 * server's own ledger, never the client: the operation must be bound
 * (readingEntitlementByOperation) to a hold of the same owner, still
 * `held`, for this operation and feature, consuming a credit from a
 * verified store purchase (a purchase lot). Trial credits, refunded holds,
 * another account's hold and unbound V3/Palm operations stay under the
 * quota. Spend guards, single consumption and single refund are unchanged.
 *
 * Real ReadingProcessor, commerce gate, entitlement ledger and ritual quota
 * over the in-memory store; the provider is a counting fake that ends each
 * paid reading with a terminal failure (no real AI), which also exercises
 * the refund path.
 */
import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { ErrorCode, ProxyError } from '../src/errors.js';
import { CoffeeV3TerminalFailure } from '../src/ai/reading/coffee-v3-live-pipeline.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../src/reading/operation-staged-image-service.js';
import { openCommerceCreate } from '../src/reading/reading-commerce-gate.js';
import { ReadingEntitlementLedger } from '../src/reading/reading-entitlement-ledger.js';
import { ReadingFlow } from '../src/reading/reading-flow.js';
import { ReadingProcessor } from '../src/reading/reading-processor.js';
import { ReadingResultRepository } from '../src/reading/reading-result-repository.js';
import { admitRitualQuota } from '../src/reading/ritual-daily-quota.js';
import { finishRitualQuota } from '../src/reading/ritual-daily-quota-settle.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import type { ServerClock } from '../src/reading/clock.js';
import { fakeJpeg, testConfig } from './helpers.js';

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date {
    return new Date(this.ms);
  }
}

const INTENTION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';
const V3_SLOTS = ['v3_cup_view_a', 'v3_cup_view_b', 'v3_saucer_view'] as const;
let seq = 0;

function world(env: Record<string, string> = {}) {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-10-27T09:00:00Z'));
  const config = testConfig({
    READING_STAGING_BUCKET: 'test-bucket',
    ORACLY_COFFEE_V3_ENABLED: 'true',
    ORACLY_READING_COMMERCE_ENABLED: 'true',
    OPENAI_API_KEY: 'sk-test-not-real',
    OPENAI_VISION: 'true',
    AI_DAILY_SPEND_CAP_USD: '5',
    ...env,
  });
  const repository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(
    repository,
    clock,
    provisionalWaitPolicy({ coffee: 1000, palm: 1000, soulmate: 1000 }),
  );
  const entitlements = new ReadingEntitlementLedger(store);
  const stagedImages = new ReadingStagedImageService(
    new FirestoreReadingStagedImageRepository(store),
    new MemoryStagedObjectStore(),
    operations,
    clock,
    config,
  );
  const calls = { coffeeV3: 0, handle: 0 };
  const processor = new ReadingProcessor(
    repository,
    new ReadingFlow(store, clock, operations, new GemLedger(store, clock, provisionalGemCostPolicy()), entitlements),
    new FirestoreReadingStagedImageRepository(store),
    stagedImages,
    new ReadingResultRepository(store),
    {
      async handle() {
        calls.handle += 1;
        if (env.TEST_PALM_SUCCESS === 'true') {
          return {
            overall: 'synthetic paid palm result',
            lifeLine: 'synthetic life',
            headLine: 'synthetic head',
            heartLine: 'synthetic heart',
            fateLine: '',
            takeaway: 'synthetic takeaway',
          };
        }
        throw new ProxyError(ErrorCode.spendGuard, 503); // terminal for Palm: failFinal + refund
      },
      async coffeeV3() {
        calls.coffeeV3 += 1;
        throw new CoffeeV3TerminalFailure('unavailable', 'test_provider_end');
      },
    },
    clock,
    undefined, // notifier
    false, // stopAfterStaged
    undefined, // providerStages
    undefined, // generationTrace
    undefined, // soulmateInputs
    undefined, // soulmatePortraits
    undefined, // soulmateEntitlement
    undefined, // soulmateImageModel
    { config, store }, // ritualQuota, as production wires it
  );

  async function useTodaysQuota(owner: string, kind: 'coffee_analysis' | 'palm_analysis', times = 1) {
    for (let i = 0; i < times; i++) {
      const admission = await admitRitualQuota({
        config, store, clock, operation: kind, identity: owner,
        idempotencyKey: `earlier-free-${kind}-${owner.slice(-6)}-${i}`,
      });
      if (admission.action !== 'hold') throw new Error(`setup: ${admission.action}`);
      await finishRitualQuota(store, owner, admission.hold, { reading: 'earlier' });
    }
  }

  async function buy(owner: string, productId: string) {
    seq += 1;
    await entitlements.grantPurchase({
      ownerUserId: owner, platform: 'android', appId: 'app.oracly', productId: productId as never,
      purchaseToken: `token-${seq}`, transactionId: `GPA.${seq}`, atMs: clock.ms,
    });
  }

  async function stage(owner: string, operationId: string, readingType: 'coffee' | 'palm') {
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

  /** Create through the real commerce gate (spends a credit when one exists). */
  async function paidCreate(owner: string, readingType: 'coffee' | 'palm', sourceRequestId = `src-${++seq}`) {
    const opened = await openCommerceCreate({
      config, store, service: operations, ownerUserId: owner, nowMs: clock.ms,
      body: readingType === 'palm'
        ? { readingType, sourceRequestId, language: 'tr' }
        : {
            readingType, sourceRequestId, language: 'tr', coffeeIntention: INTENTION,
            coffeeInputContract: 'trusted_intention_v1', coffeeCaptureContract: 'three_view_v3',
          },
    });
    if (opened.kind !== 'record') return opened;
    await stage(owner, opened.record.operationId, readingType);
    return opened;
  }

  /** A V3 / Palm operation created without the gate: no credit, no hold
   *  (instant like the paid path, so only the ledger binding differs). */
  async function unboundCreate(owner: string, readingType: 'coffee' | 'palm') {
    const op = await operations.create(readingType === 'palm'
      ? { ownerUserId: owner, readingType, sourceRequestId: `free-${++seq}`, instant: true }
      : {
          ownerUserId: owner, readingType, sourceRequestId: `free-${++seq}`,
          coffeeInputContract: 'trusted_intention_v1', coffeeIntention: INTENTION,
          coffeeCaptureContract: 'three_view_v3', instant: true,
        });
    await stage(owner, op.operationId, readingType);
    return op.operationId;
  }

  const balance = async (owner: string) => entitlements.balance(owner);
  const failure = async (owner: string, operationId: string) =>
    (await operations.get(owner, operationId)).failureCode;

  /** One unslotted image, the legacy Coffee input. */
  async function stageLegacy(owner: string, operationId: string) {
    await stagedImages.stage({
      ownerUserId: owner, operationId, mimeType: 'image/jpeg',
      imageBase64: fakeJpeg(13_000).toString('base64'),
    });
  }

  return {
    store, clock, config, operations, entitlements, processor, calls, stageLegacy,
    useTodaysQuota, buy, paidCreate, unboundCreate, balance, failure,
  };
}

describe('paid readings are not limited by the free daily quota', () => {
  it('paid Palm is instant, consumes once, persists one worker result and spends zero gems',
    async () => {
      const w = world({ TEST_PALM_SUCCESS: 'true' });
      const owner = identityKeyFromSubject('paid-palm-success');
      await w.buy(owner, 'app.oracly.reading.palm');
      const opened = await w.paidCreate(owner, 'palm', 'same-paid-palm');
      expect(opened.kind).toBe('record');
      if (opened.kind !== 'record') return;
      expect(opened.record.readyAtMs).toBe(opened.record.createdAtMs);
      expect((await w.balance(owner)).palm).toBe(0);

      await Promise.allSettled([
        w.processor.process(opened.record.operationId),
        w.processor.process(opened.record.operationId),
      ]);
      expect(w.calls.handle).toBe(1);
      expect((await w.balance(owner)).palm).toBe(0);
      const completed = await w.operations.get(owner, opened.record.operationId);
      expect(completed.status).toBe('ready');
      expect(completed.gemDebitId).toBeNull();
      expect(await new ReadingResultRepository(w.store).get(opened.record.operationId))
        .toMatchObject({ ownerUserId: owner, readingType: 'palm' });

      const replay = await w.paidCreate(owner, 'palm', 'same-paid-palm');
      expect(replay.kind).toBe('record');
      if (replay.kind === 'record') {
        expect(replay.record.operationId).toBe(opened.record.operationId);
      }
      expect((await w.balance(owner)).palm).toBe(0);
    });

  it('a second and third paid Coffee V3 the same day reach the provider, one '
    + 'credit each, refunded once each on a terminal failure', async () => {
    const w = world();
    const owner = identityKeyFromSubject('paid-coffee');
    await w.useTodaysQuota(owner, 'coffee_analysis');
    await w.buy(owner, 'app.oracly.reading.coffee.pack3');
    expect((await w.balance(owner)).coffee).toBe(3);
    const ops: string[] = [];
    for (let i = 0; i < 3; i++) {
      const opened = await w.paidCreate(owner, 'coffee');
      expect(opened.kind).toBe('record');
      if (opened.kind === 'record') ops.push(opened.record.operationId);
    }
    expect((await w.balance(owner)).coffee).toBe(0);
    for (const op of ops) {
      await w.processor.process(op);
      expect(await w.failure(owner, op)).not.toBe('daily_quota');
    }
    expect(w.calls.coffeeV3).toBe(3);
    expect((await w.balance(owner)).coffee).toBe(3); // each terminal failure refunded once
  });

  it('a paid Palm reading past the free palm quota reaches the provider',
    async () => {
      const w = world();
      const owner = identityKeyFromSubject('paid-palm');
      await w.useTodaysQuota(owner, 'palm_analysis', 2);
      await w.buy(owner, 'app.oracly.reading.palm');
      const opened = await w.paidCreate(owner, 'palm');
      expect(opened.kind).toBe('record');
      if (opened.kind !== 'record') return;
      await w.processor.process(opened.record.operationId);
      expect(w.calls.handle).toBe(1);
      expect(await w.failure(owner, opened.record.operationId)).not.toBe('daily_quota');
      expect((await w.balance(owner)).palm).toBe(1); // refunded once
    });

  it('worker retries of one paid reading call the provider once and refund once',
    async () => {
      const w = world();
      const owner = identityKeyFromSubject('paid-retry');
      await w.useTodaysQuota(owner, 'coffee_analysis');
      await w.buy(owner, 'app.oracly.reading.coffee');
      const opened = await w.paidCreate(owner, 'coffee');
      if (opened.kind !== 'record') throw new Error('setup');
      await w.processor.process(opened.record.operationId);
      await w.processor.process(opened.record.operationId);
      await Promise.allSettled([
        w.processor.process(opened.record.operationId),
        w.processor.process(opened.record.operationId),
      ]);
      expect(w.calls.coffeeV3).toBe(1);
      expect((await w.balance(owner)).coffee).toBe(1);
    });
});

describe('nothing else escapes the free daily quota', () => {
  it('an unbound Coffee V3 (three_view_v3 alone) is still refused', async () => {
    const w = world();
    const owner = identityKeyFromSubject('unbound-v3');
    await w.useTodaysQuota(owner, 'coffee_analysis');
    const op = await w.unboundCreate(owner, 'coffee');
    await w.processor.process(op);
    expect(w.calls.coffeeV3).toBe(0);
    expect(await w.failure(owner, op)).toBe('daily_quota');
  });

  it('an unbound Palm (palm alone) is still refused', async () => {
    const w = world();
    const owner = identityKeyFromSubject('unbound-palm');
    await w.useTodaysQuota(owner, 'palm_analysis', 2);
    const op = await w.unboundCreate(owner, 'palm');
    await w.processor.process(op);
    expect(w.calls.handle).toBe(0);
    expect(await w.failure(owner, op)).toBe('daily_quota');
  });

  it('a trial credit (no store purchase) gives no exemption', async () => {
    const w = world({ ORACLY_READING_TRIAL_ENABLED: 'true' });
    const owner = identityKeyFromSubject('trial');
    await w.useTodaysQuota(owner, 'coffee_analysis');
    await w.entitlements.grantTrial({ ownerUserId: owner, atMs: w.clock.ms } as never);
    const opened = await w.paidCreate(owner, 'coffee');
    if (opened.kind !== 'record') throw new Error(`setup: ${JSON.stringify(opened)}`);
    await w.processor.process(opened.record.operationId);
    expect(w.calls.coffeeV3).toBe(0);
    expect(await w.failure(owner, opened.record.operationId)).toBe('daily_quota');
  });

  it('a refunded hold gives no exemption, and is not refunded twice', async () => {
    const w = world();
    const owner = identityKeyFromSubject('refunded');
    await w.useTodaysQuota(owner, 'coffee_analysis');
    await w.buy(owner, 'app.oracly.reading.coffee');
    const opened = await w.paidCreate(owner, 'coffee');
    if (opened.kind !== 'record') throw new Error('setup');
    expect(await w.entitlements.restoreByOperation(owner, opened.record.operationId)).toBe(true);
    await w.processor.process(opened.record.operationId);
    expect(w.calls.coffeeV3).toBe(0);
    expect(await w.failure(owner, opened.record.operationId)).toBe('daily_quota');
    expect((await w.balance(owner)).coffee).toBe(1);
  });

  // Ledger records are server-only (firestore.rules deny clients); these
  // forge them directly to prove each condition of the proof on its own.
  async function holdOf(w: ReturnType<typeof world>, operationId: string): Promise<string> {
    return (await w.store.collection('readingEntitlementByOperation')
      .doc(operationId).get()).data()!.holdId as string;
  }
  async function forge(
    w: ReturnType<typeof world>,
    operationId: string,
    holdId: string,
    pointerOwner: string,
    rebindHold: boolean,
  ) {
    await w.store.runTransaction(async (tx) => {
      tx.set(w.store.collection('readingEntitlementByOperation').doc(operationId),
        { holdId, ownerUserId: pointerOwner });
      if (rebindHold) {
        const ref = w.store.collection('readingEntitlementHolds').doc(holdId);
        tx.set(ref, { ...(await tx.get(ref)).data(), operationId });
      }
    });
  }

  it('one purchased credit cannot exempt a second operation of its owner',
    async () => {
      const w = world();
      const owner = identityKeyFromSubject('credit-reuse');
      await w.useTodaysQuota(owner, 'coffee_analysis');
      await w.buy(owner, 'app.oracly.reading.coffee');
      const paid = await w.paidCreate(owner, 'coffee');
      if (paid.kind !== 'record') throw new Error('setup');
      const second = await w.unboundCreate(owner, 'coffee');
      await forge(w, second, await holdOf(w, paid.record.operationId), owner, false);
      await w.processor.process(second);
      expect(w.calls.coffeeV3).toBe(0);
      expect(await w.failure(owner, second)).toBe('daily_quota');
    });

  for (const pointerOwner of ['self', 'other'] as const) {
    it(`another account's purchased hold gives no exemption (pointer owner: ${pointerOwner})`,
      async () => {
        const w = world();
        const a = identityKeyFromSubject('owner-a');
        const b = identityKeyFromSubject('owner-b');
        await w.buy(b, 'app.oracly.reading.coffee');
        const paidB = await w.paidCreate(b, 'coffee');
        if (paidB.kind !== 'record') throw new Error('setup');
        await w.useTodaysQuota(a, 'coffee_analysis');
        const opA = await w.unboundCreate(a, 'coffee');
        await forge(w, opA, await holdOf(w, paidB.record.operationId), pointerOwner === 'self' ? a : b, true);
        await w.processor.process(opA);
        expect(w.calls.coffeeV3).toBe(0);
        expect(await w.failure(a, opA)).toBe('daily_quota');
      });
  }

  it('a purchased Coffee credit does not exempt a Palm reading', async () => {
    const w = world();
    const owner = identityKeyFromSubject('feature-mismatch');
    await w.useTodaysQuota(owner, 'palm_analysis', 2);
    await w.buy(owner, 'app.oracly.reading.coffee');
    const paid = await w.paidCreate(owner, 'coffee');
    if (paid.kind !== 'record') throw new Error('setup');
    const palm = await w.unboundCreate(owner, 'palm');
    await forge(w, palm, await holdOf(w, paid.record.operationId), owner, true);
    await w.processor.process(palm);
    expect(w.calls.handle).toBe(0);
    expect(await w.failure(owner, palm)).toBe('daily_quota');
  });

  it('a purchased Coffee credit does not exempt a legacy (non-V3) Coffee', async () => {
    const w = world();
    const owner = identityKeyFromSubject('legacy-coffee');
    await w.useTodaysQuota(owner, 'coffee_analysis');
    await w.buy(owner, 'app.oracly.reading.coffee');
    const paid = await w.paidCreate(owner, 'coffee');
    if (paid.kind !== 'record') throw new Error('setup');
    // A legacy operation bound to the purchased hold: the type gate must hold.
    const legacy = await w.operations.create({
      ownerUserId: owner, readingType: 'coffee', sourceRequestId: 'legacy-src', instant: true,
    });
    await w.stageLegacy(owner, legacy.operationId);
    await forge(w, legacy.operationId, await holdOf(w, paid.record.operationId), owner, true);
    await w.processor.process(legacy.operationId);
    expect(w.calls.coffeeV3 + w.calls.handle).toBe(0);
    expect(await w.failure(owner, legacy.operationId)).toBe('daily_quota');
  });
});

describe('guards around paid readings are unchanged', () => {
  it('no credit: the gate refuses before anything is created', async () => {
    const w = world();
    const owner = identityKeyFromSubject('no-credit');
    const opened = await w.paidCreate(owner, 'coffee');
    expect(opened).toMatchObject({ kind: 'error', httpStatus: 403 });
  });

  it('AI kill switch: the gate refuses and no credit is spent', async () => {
    const w = world({ AI_SPEND_KILL_SWITCH: 'true' });
    const owner = identityKeyFromSubject('kill-switch');
    await w.buy(owner, 'app.oracly.reading.coffee');
    const opened = await w.paidCreate(owner, 'coffee');
    expect(opened).toMatchObject({ kind: 'error', httpStatus: 503 });
    expect((await w.balance(owner)).coffee).toBe(1);
  });

  it('the same request twice (lost response) spends one credit', async () => {
    const w = world();
    const owner = identityKeyFromSubject('idempotent');
    await w.buy(owner, 'app.oracly.reading.coffee.pack3');
    const [a, b] = await Promise.all([
      w.paidCreate(owner, 'coffee', 'same-source'),
      w.paidCreate(owner, 'coffee', 'same-source'),
    ]);
    expect(a.kind).toBe('record');
    expect(b.kind).toBe('record');
    if (a.kind === 'record' && b.kind === 'record') {
      expect(a.record.operationId).toBe(b.record.operationId);
    }
    expect((await w.balance(owner)).coffee).toBe(2);
  });

  it('a free reading with the quota left still runs (control)', async () => {
    const w = world();
    const owner = identityKeyFromSubject('free-control');
    const op = await w.unboundCreate(owner, 'coffee');
    await w.processor.process(op);
    expect(w.calls.coffeeV3).toBe(1);
  });
});
