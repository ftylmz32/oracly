/**
 * Büyük Final Aşama 01 / F1 — the full lifecycle of a coffee reading whose
 * owner already used today's coffee allowance, after they paid gems to
 * accelerate it. Real ReadingProcessor, ReadingFlow, GemLedger and ritual
 * quota code over the in-memory document store; only the AI provider is a
 * counting fake (it must never be called). Measures current behavior; no
 * source is changed by this file.
 *
 * Expected: the operation ends `failed` with `failureCode: daily_quota`
 * and stays readable as such; the gem debit is refunded in full exactly
 * once, also across worker retries, concurrent workers and repeated
 * acceleration requests; another account is unaffected; and the outcome
 * is not silent in the worker log.
 */
import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../src/reading/operation-staged-image-service.js';
import { toPublicStatus } from '../src/reading/operation-model.js';
import { ReadingFlow } from '../src/reading/reading-flow.js';
import { ReadingProcessor } from '../src/reading/reading-processor.js';
import { ReadingResultRepository } from '../src/reading/reading-result-repository.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import { admitRitualQuota } from '../src/reading/ritual-daily-quota.js';
import { finishRitualQuota } from '../src/reading/ritual-daily-quota-settle.js';
import type { ServerClock } from '../src/reading/clock.js';
import { fakeJpeg, testConfig } from './helpers.js';

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date {
    return new Date(this.ms);
  }
}

const SEED = 40;
const INTENTION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';
const V3_SLOTS = ['v3_cup_view_a', 'v3_cup_view_b', 'v3_saucer_view'] as const;

async function world() {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-10-23T21:00:00Z'));
  const config = testConfig({
    READING_STAGING_BUCKET: 'test-bucket',
    ORACLY_COFFEE_V3_ENABLED: 'true',
  });
  const repository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(
    repository,
    clock,
    provisionalWaitPolicy({ coffee: 1000, palm: 1000, soulmate: 1000 }),
  );
  const ledger = new GemLedger(store, clock, provisionalGemCostPolicy());
  const objects = new MemoryStagedObjectStore();
  const stagedImages = new ReadingStagedImageService(
    new FirestoreReadingStagedImageRepository(store),
    objects,
    operations,
    clock,
    config,
  );
  let providerCalls = 0;
  let v3Calls = 0;
  const logs: Array<Record<string, unknown>> = [];
  const log = {
    info: (fields: Record<string, unknown>) => void logs.push({ level: 'info', ...fields }),
    error: (fields: Record<string, unknown>) => void logs.push({ level: 'error', ...fields }),
  };
  const processor = new ReadingProcessor(
    repository,
    new ReadingFlow(store, clock, operations, ledger),
    new FirestoreReadingStagedImageRepository(store),
    stagedImages,
    new ReadingResultRepository(store),
    {
      async handle() {
        providerCalls += 1;
        return { reading: 'synthetic' };
      },
      async coffeeV3() {
        v3Calls += 1;
        throw new Error('the V3 provider must not be reached');
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
    { config, store }, // ritualQuota, as production wires it (index.ts)
  );

  /** Today's coffee allowance already used by a delivered reading. */
  async function useTodaysCoffee(owner: string) {
    const admission = await admitRitualQuota({
      config,
      store,
      clock,
      operation: 'coffee_analysis',
      identity: owner,
      idempotencyKey: 'earlier-coffee-op-0001',
    });
    if (admission.action !== 'hold') throw new Error(`setup: ${admission.action}`);
    await finishRitualQuota(store, owner, admission.hold, { reading: 'earlier' });
  }

  /** A staged coffee operation the owner paid gems to accelerate. */
  async function acceleratedCoffee(owner: string, seq: string) {
    await ledger.credit({ ownerUserId: owner, amount: SEED, idempotencyKey: `f1-seed-credit-${seq}` });
    const op = await operations.create({
      ownerUserId: owner,
      readingType: 'coffee',
      sourceRequestId: `f1-quota-${seq}`,
    });
    await stagedImages.stage({
      ownerUserId: owner,
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: fakeJpeg(12_000).toString('base64'),
    });
    await ledger.accelerate({
      ownerUserId: owner,
      operationId: op.operationId,
      idempotencyKey: `f1-accelerate-${seq}`,
    });
    // Due for the worker.
    await repository.mutate(op.operationId, owner, (current) => ({
      ...current,
      executionStartedAtMs: clock.ms - 13 * 60 * 1000,
    }));
    return op.operationId;
  }

  /** Every gem transaction document for this operation, by type. */
  function transactionsFor(operationId: string) {
    const out: string[] = [];
    for (const [path, data] of store.docs) {
      if (path.startsWith('gemTransactions/') && data.operationId === operationId) {
        out.push(String(data.type));
      }
    }
    return out.sort();
  }

  /** A staged 2-cup + 1-saucer V3 operation, accelerated with gems. */
  async function acceleratedCoffeeV3(owner: string, seq: string) {
    await ledger.credit({ ownerUserId: owner, amount: SEED, idempotencyKey: `f1-seed-credit-${seq}` });
    const op = await operations.create({
      ownerUserId: owner,
      readingType: 'coffee',
      sourceRequestId: `f1-quota-v3-${seq}`,
      coffeeInputContract: 'trusted_intention_v1',
      coffeeIntention: INTENTION,
      coffeeCaptureContract: 'three_view_v3',
    });
    let n = 0;
    for (const slot of V3_SLOTS) {
      n += 1;
      await stagedImages.stage({
        ownerUserId: owner,
        operationId: op.operationId,
        mimeType: 'image/jpeg',
        imageBase64: fakeJpeg(12_000 + n).toString('base64'),
        slot,
      });
    }
    await ledger.accelerate({
      ownerUserId: owner,
      operationId: op.operationId,
      idempotencyKey: `f1-accelerate-${seq}`,
    });
    await repository.mutate(op.operationId, owner, (current) => ({
      ...current,
      executionStartedAtMs: clock.ms - 13 * 60 * 1000,
    }));
    return op.operationId;
  }

  return {
    store,
    clock,
    objects,
    v3Calls: () => v3Calls,
    acceleratedCoffeeV3,
    ledger,
    operations,
    processor,
    log,
    logs,
    calls: () => providerCalls,
    useTodaysCoffee,
    acceleratedCoffee,
    transactionsFor,
  };
}

describe('F1: coffee daily quota already used, reading accelerated with gems', () => {
  it('ends failed with daily_quota, readable as such, never calling the provider',
    async () => {
      const w = await world();
      const owner = identityKeyFromSubject('f1-owner-a');
      await w.useTodaysCoffee(owner);
      const opId = await w.acceleratedCoffee(owner, 'a1');
      expect(await w.ledger.balanceOf(owner)).toBeLessThan(SEED);

      await expect(w.processor.process(opId, w.log)).resolves.toBe('failed');

      expect(w.calls()).toBe(0);
      const record = await w.operations.get(owner, opId);
      expect(record.status).toBe('failed');
      expect(record.failureCode).toBe('daily_quota');
      // What the app polls: an explicit failure with its code, not a spinner.
      const view = toPublicStatus(record, w.clock.ms);
      expect(view).toMatchObject({
        status: 'failed',
        failureCode: 'daily_quota',
        resultReady: false,
        resultId: null,
        accelerated: true,
      });
    });

  it('refunds the gem debit in full, exactly once', async () => {
    const w = await world();
    const owner = identityKeyFromSubject('f1-owner-b');
    await w.useTodaysCoffee(owner);
    const opId = await w.acceleratedCoffee(owner, 'b1');
    await w.processor.process(opId, w.log);
    expect(await w.ledger.balanceOf(owner)).toBe(SEED);
    expect(w.transactionsFor(opId)).toEqual(['refund', 'spend']);
  });

  it('a retried worker run refunds nothing more and changes nothing', async () => {
    const w = await world();
    const owner = identityKeyFromSubject('f1-owner-c');
    await w.useTodaysCoffee(owner);
    const opId = await w.acceleratedCoffee(owner, 'c1');
    await w.processor.process(opId, w.log);
    const again = await w.processor.process(opId, w.log);
    expect(again).not.toBe('completed');
    expect(await w.ledger.balanceOf(owner)).toBe(SEED);
    expect(w.transactionsFor(opId)).toEqual(['refund', 'spend']);
    expect((await w.operations.get(owner, opId)).failureCode).toBe('daily_quota');
    expect(w.calls()).toBe(0);
  });

  it('two concurrent worker runs refund exactly once', async () => {
    const w = await world();
    const owner = identityKeyFromSubject('f1-owner-d');
    await w.useTodaysCoffee(owner);
    const opId = await w.acceleratedCoffee(owner, 'd1');
    await Promise.allSettled([
      w.processor.process(opId, w.log),
      w.processor.process(opId, w.log),
    ]);
    expect(await w.ledger.balanceOf(owner)).toBe(SEED);
    expect(w.transactionsFor(opId)).toEqual(['refund', 'spend']);
    expect((await w.operations.get(owner, opId)).status).toBe('failed');
  });

  it('accelerating the failed reading again, same key or new, never debits',
    async () => {
      const w = await world();
      const owner = identityKeyFromSubject('f1-owner-e');
      await w.useTodaysCoffee(owner);
      const opId = await w.acceleratedCoffee(owner, 'e1');
      await w.processor.process(opId, w.log);
      for (const key of ['f1-accelerate-e1', 'f1-accelerate-e1-retry']) {
        await w.ledger
          .accelerate({ ownerUserId: owner, operationId: opId, idempotencyKey: key })
          .catch(() => undefined);
      }
      expect(await w.ledger.balanceOf(owner)).toBe(SEED);
      expect(w.transactionsFor(opId)).toEqual(['refund', 'spend']);
    });

  it('another account is untouched and its coffee reaches the provider', async () => {
    const w = await world();
    const a = identityKeyFromSubject('f1-owner-f');
    const b = identityKeyFromSubject('f1-owner-g');
    await w.useTodaysCoffee(a);
    const opA = await w.acceleratedCoffee(a, 'f1');
    const opB = await w.acceleratedCoffee(b, 'g1');
    const balanceB = await w.ledger.balanceOf(b);
    await w.processor.process(opA, w.log);
    expect(await w.ledger.balanceOf(b)).toBe(balanceB);
    expect(w.transactionsFor(opB)).toEqual(['spend']);
    await w.processor.process(opB, w.log);
    // A's quota does not apply to B: B's reading is admitted to the
    // provider. (The counting fake returns no valid coffee payload, so B
    // then ends at the existing legacy terminal check; that outcome is the
    // fake's, never daily_quota.)
    expect(w.calls()).toBe(1);
    expect((await w.operations.get(b, opB)).failureCode).not.toBe('daily_quota');
    expect(await w.ledger.balanceOf(a)).toBe(SEED);
    expect(w.transactionsFor(opA)).toEqual(['refund', 'spend']);
  });

  it('V3 (2 cups + 1 saucer): failed daily_quota, refunded once, provider '
    + 'never reached, the three views cleaned', async () => {
    const w = await world();
    const owner = identityKeyFromSubject('f1-owner-v3');
    await w.useTodaysCoffee(owner);
    const opId = await w.acceleratedCoffeeV3(owner, 'v3a');
    expect(w.objects.objects.size).toBe(3);
    expect(await w.ledger.balanceOf(owner)).toBeLessThan(SEED);

    await expect(w.processor.process(opId, w.log)).resolves.toBe('failed');
    await w.processor.process(opId, w.log);

    expect(w.v3Calls()).toBe(0);
    expect(w.calls()).toBe(0);
    const record = await w.operations.get(owner, opId);
    expect(record).toMatchObject({ status: 'failed', failureCode: 'daily_quota' });
    expect(toPublicStatus(record, w.clock.ms)).toMatchObject({
      status: 'failed',
      failureCode: 'daily_quota',
      resultReady: false,
      accelerated: true,
    });
    expect(await w.ledger.balanceOf(owner)).toBe(SEED);
    expect(w.transactionsFor(opId)).toEqual(['refund', 'spend']);
    expect(w.objects.objects.size).toBe(0);
  });

  // F1 FAIL (current code, reading-processor-execute.ts ritual 'reply'
  // branch): the daily_quota exit writes no log event, unlike every other
  // terminal exit. Marked `it.fails` so the suite records the defect; when
  // the log is added this flips to a failure and must become `it`.
  it.fails('[F1 FAIL] the daily_quota outcome is not silent: the worker logs it', async () => {
    const w = await world();
    const owner = identityKeyFromSubject('f1-owner-h');
    await w.useTodaysCoffee(owner);
    const opId = await w.acceleratedCoffee(owner, 'h1');
    await w.processor.process(opId, w.log);
    const ours = w.logs.filter((l) => l.operationId === opId);
    // Every other terminal exit logs an event naming its outcome
    // (coffee_v3_terminal_failure, spend_guard_rejected,
    // provider_outcome_unknown). This one must too.
    expect(
      ours.some((l) => JSON.stringify(l).includes('daily_quota')),
      `worker log for the op: ${JSON.stringify(ours.map((l) => l.event))}`,
    ).toBe(true);
  });
});
