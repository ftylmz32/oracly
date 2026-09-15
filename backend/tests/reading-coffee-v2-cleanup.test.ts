/**
 * Coffee 3-Photo Reading V2 — Phase 2B: staged-asset cleanup lifecycle.
 *
 * Exercises `ReadingStagedImageService.deleteCoffeeV2Slots` directly (unit
 * level, per spec sections 16/17) and, for the success/retry lifecycle
 * points, through the real durable processor (`ReadingProcessor.process`)
 * with a fake AI transport -- zero paid provider calls anywhere here.
 */
import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../src/reading/operation-staged-image-service.js';
import { ReadingFlow } from '../src/reading/reading-flow.js';
import { ReadingProcessor, NoopReadingCompletionNotifier } from '../src/reading/reading-processor.js';
import { ReadingResultRepository } from '../src/reading/reading-result-repository.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import { fakeJpeg, testConfig } from './helpers.js';
import type { ServerClock } from '../src/reading/clock.js';

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date {
    return new Date(this.ms);
  }
}

function harness() {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-09-12T00:00:00.000Z'));
  const policy = provisionalWaitPolicy({ coffee: 1000, palm: 1000, soulmate: 1000 });
  const operationRepository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(operationRepository, clock, policy);
  const stagedRepository = new FirestoreReadingStagedImageRepository(store);
  const objects = new MemoryStagedObjectStore();
  const config = testConfig();
  const service = new ReadingStagedImageService(stagedRepository, objects, operations, clock, config);
  return { store, clock, operationRepository, operations, stagedRepository, objects, config, service };
}

async function coffeeOp(h: ReturnType<typeof harness>, owner = 'owner-a') {
  return h.operations.create({
    ownerUserId: owner,
    readingType: 'coffee',
    sourceRequestId: `req-v2-cleanup-${owner}-${Math.random().toString(36).slice(2)}`,
  });
}

function stageSlot(
  h: ReturnType<typeof harness>,
  operationId: string,
  slot: 'cup_primary' | 'cup_secondary' | 'saucer',
  bytes: Buffer,
  owner = 'owner-a',
) {
  return h.service.stage({
    ownerUserId: owner,
    operationId,
    mimeType: 'image/jpeg',
    imageBase64: bytes.toString('base64'),
    slot,
  });
}

describe('deleteCoffeeV2Slots — unit level', () => {
  it('Y deletes all three slots (GCS objects and Firestore records)', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await stageSlot(h, op.operationId, 'cup_primary', fakeJpeg(9000));
    await stageSlot(h, op.operationId, 'cup_secondary', fakeJpeg(9100));
    await stageSlot(h, op.operationId, 'saucer', fakeJpeg(9200));
    expect(h.objects.objects.size).toBe(3);

    await h.service.deleteCoffeeV2Slots({ ownerUserId: 'owner-a', operationId: op.operationId });

    expect(h.objects.objects.size).toBe(0);
    const slots = await h.stagedRepository.listSlots(op.operationId, 'owner-a');
    expect(slots).toHaveLength(0);
  });

  it('AB calling cleanup twice is safe (idempotent)', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await stageSlot(h, op.operationId, 'cup_primary', fakeJpeg(9000));
    await stageSlot(h, op.operationId, 'cup_secondary', fakeJpeg(9100));
    await stageSlot(h, op.operationId, 'saucer', fakeJpeg(9200));

    await h.service.deleteCoffeeV2Slots({ ownerUserId: 'owner-a', operationId: op.operationId });
    await expect(
      h.service.deleteCoffeeV2Slots({ ownerUserId: 'owner-a', operationId: op.operationId }),
    ).resolves.toBeUndefined();
    expect(h.objects.objects.size).toBe(0);
  });

  it('AC missing one slot during cleanup does not prevent deleting the others', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await stageSlot(h, op.operationId, 'cup_primary', fakeJpeg(9000));
    await stageSlot(h, op.operationId, 'saucer', fakeJpeg(9200));
    // cup_secondary was never staged at all.

    await expect(
      h.service.deleteCoffeeV2Slots({ ownerUserId: 'owner-a', operationId: op.operationId }),
    ).resolves.toBeUndefined();
    expect(await h.stagedRepository.getSlot(op.operationId, 'cup_primary', 'owner-a')).toBeNull();
    expect(await h.stagedRepository.getSlot(op.operationId, 'saucer', 'owner-a')).toBeNull();
  });

  it('never touches another owner\'s slots', async () => {
    const h = harness();
    const opA = await coffeeOp(h, 'owner-a');
    await stageSlot(h, opA.operationId, 'cup_primary', fakeJpeg(9000), 'owner-a');
    await h.service.deleteCoffeeV2Slots({ ownerUserId: 'owner-b', operationId: opA.operationId });
    // Wrong-owner cleanup is a safe no-op -- the real slot survives.
    expect(await h.stagedRepository.getSlot(opA.operationId, 'cup_primary', 'owner-a')).not.toBeNull();
  });
});

describe('AD legacy delete() regression', () => {
  it('legacy single-image delete remains unchanged', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await h.service.stage({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: fakeJpeg().toString('base64'),
    });
    await h.service.delete({ ownerUserId: 'owner-a', operationId: op.operationId });
    await expect(
      h.service.delete({ ownerUserId: 'owner-a', operationId: op.operationId }),
    ).resolves.toBeUndefined();
    expect(await h.stagedRepository.get(op.operationId, 'owner-a')).toBeNull();
    expect(h.objects.objects.size).toBe(0);
  });
});

describe('Full lifecycle — cleanup timing via the real durable processor (fake AI, 0 paid calls)', () => {
  function processorHarness() {
    const h = harness();
    const ledger = new GemLedger(h.store, h.clock, provisionalGemCostPolicy());
    const flow = new ReadingFlow(h.store, h.clock, h.operations, ledger);
    const results = new ReadingResultRepository(h.store);
    let providerCalls = 0;
    let failProvider = false;
    const ai = {
      async handle() {
        providerCalls++;
        if (failProvider) throw new Error('simulated_transient_provider_failure');
        return { overall: 'v2 result', love: '', career: '', money: '', nearFuture: '', takeaway: 'done', symbols: [] };
      },
    };
    const processor = new ReadingProcessor(
      h.operationRepository,
      flow,
      h.stagedRepository,
      h.service,
      results,
      ai,
      h.clock,
      new NoopReadingCompletionNotifier(),
    );
    const owner = identityKeyFromSubject('coffee-v2-cleanup-durable-user');
    return {
      ...h,
      flow,
      results,
      processor,
      owner,
      providerCalls: () => providerCalls,
      setProviderFailure: (v: boolean) => {
        failProvider = v;
      },
    };
  }

  it('Y (processor-level) success deletes all three V2 slots at the same lifecycle point legacy staging is cleaned', async () => {
    const h = processorHarness();
    const op = await h.operations.create({ ownerUserId: h.owner, readingType: 'coffee', sourceRequestId: 'coffee-v2-cleanup-y' });
    await h.flow.remember(op);
    await stageSlot(h, op.operationId, 'cup_primary', fakeJpeg(9000), h.owner);
    await stageSlot(h, op.operationId, 'cup_secondary', fakeJpeg(9100), h.owner);
    await stageSlot(h, op.operationId, 'saucer', fakeJpeg(9200), h.owner);
    h.clock.ms = op.readyAtMs;

    expect(await h.processor.process(op.operationId)).toBe('completed');
    expect(h.providerCalls()).toBe(1);
    expect(h.objects.objects.size).toBe(0);
    expect(await h.stagedRepository.listSlots(op.operationId, h.owner)).toHaveLength(0);
  });

  it('Z a retryable processing error deletes NONE of the staged V2 assets', async () => {
    const h = processorHarness();
    h.setProviderFailure(true);
    const op = await h.operations.create({ ownerUserId: h.owner, readingType: 'coffee', sourceRequestId: 'coffee-v2-cleanup-z' });
    await h.flow.remember(op);
    await stageSlot(h, op.operationId, 'cup_primary', fakeJpeg(9000), h.owner);
    await stageSlot(h, op.operationId, 'cup_secondary', fakeJpeg(9100), h.owner);
    await stageSlot(h, op.operationId, 'saucer', fakeJpeg(9200), h.owner);
    h.clock.ms = op.readyAtMs;

    await expect(h.processor.process(op.operationId)).rejects.toMatchObject({ retryable: true });
    expect(h.objects.objects.size).toBe(3);
    expect(await h.stagedRepository.listSlots(op.operationId, h.owner)).toHaveLength(3);

    // A restart/retry must still be able to continue -- the images are
    // still there for a subsequent successful attempt.
    h.setProviderFailure(false);
    expect(await h.processor.process(op.operationId)).toBe('completed');
    expect(h.objects.objects.size).toBe(0);
  });

  it('partial upload: an incomplete V2 set is never cleaned up merely because one slot is temporarily missing', async () => {
    const h = processorHarness();
    const op = await h.operations.create({ ownerUserId: h.owner, readingType: 'coffee', sourceRequestId: 'coffee-v2-cleanup-partial' });
    await h.flow.remember(op);
    await stageSlot(h, op.operationId, 'cup_primary', fakeJpeg(9000), h.owner);
    h.clock.ms = op.readyAtMs;

    await expect(h.processor.process(op.operationId)).rejects.toMatchObject({ retryable: true });
    expect(h.providerCalls()).toBe(0);
    // The one successfully staged slot must survive so the restart/retake
    // flow can still complete the remaining two without re-uploading it.
    expect(await h.stagedRepository.getSlot(op.operationId, 'cup_primary', h.owner)).not.toBeNull();

    // Completing the remaining slots and retrying succeeds normally.
    await stageSlot(h, op.operationId, 'cup_secondary', fakeJpeg(9100), h.owner);
    await stageSlot(h, op.operationId, 'saucer', fakeJpeg(9200), h.owner);
    expect(await h.processor.process(op.operationId)).toBe('completed');
    expect(h.providerCalls()).toBe(1);
    expect(h.objects.objects.size).toBe(0);
  });
});
