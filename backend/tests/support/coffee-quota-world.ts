/**
 * F1 test world: real ReadingProcessor, ReadingFlow, GemLedger and ritual
 * quota code over the in-memory store, with a counting fake provider.
 * Shared by the F1 lifecycle test and the worker route outcome-log test.
 */
import { identityKeyFromSubject } from '../../src/auth/identity.js';
import { MemoryDocumentStore } from '../../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../../src/reading/memory-staged-object-store.js';
import { FirestoreReadingOperationRepository } from '../../src/reading/operation-repository.js';
import { ReadingOperationService } from '../../src/reading/operation-service.js';
import { FirestoreReadingStagedImageRepository } from '../../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../../src/reading/operation-staged-image-service.js';
import { ReadingFlow } from '../../src/reading/reading-flow.js';
import { ReadingProcessor } from '../../src/reading/reading-processor.js';
import { ReadingResultRepository } from '../../src/reading/reading-result-repository.js';
import { GemLedger } from '../../src/reading/gem-ledger.js';
import { provisionalGemCostPolicy } from '../../src/reading/gem-cost-policy.js';
import { provisionalWaitPolicy } from '../../src/reading/wait-policy.js';
import { admitRitualQuota } from '../../src/reading/ritual-daily-quota.js';
import { finishRitualQuota } from '../../src/reading/ritual-daily-quota-settle.js';
import type { ServerClock } from '../../src/reading/clock.js';
import { fakeJpeg, testConfig } from '../helpers.js';

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date {
    return new Date(this.ms);
  }
}

export const SEED = 40;
const INTENTION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';
const V3_SLOTS = ['v3_cup_view_a', 'v3_cup_view_b', 'v3_saucer_view'] as const;

export async function world() {
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
