/**
 * Coffee 3-Photo Reading V2 — Phase 2A: slotted staging foundation.
 *
 * These tests are additive and Coffee-specific. They never touch the
 * legacy single-image path's own test file (reading-staged-image.test.ts),
 * which is re-run unmodified as the regression proof that legacy Coffee
 * and Palm behavior is unaffected by this phase (see the harness re-used
 * below, identical to that file's).
 */
import { describe, expect, it } from 'vitest';
import { fakeJpeg, testConfig } from './helpers.js';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import {
  COFFEE_V2_SLOTS,
  stagedDocId,
  stagedObjectPath,
} from '../src/reading/operation-staged-image-model.js';
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../src/reading/operation-staged-image-service.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationError, ReadingOperationService } from '../src/reading/operation-service.js';
import { ReadingFlow } from '../src/reading/reading-flow.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { ReadingProcessor, NoopReadingCompletionNotifier } from '../src/reading/reading-processor.js';
import { ReadingResultRepository } from '../src/reading/reading-result-repository.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import { ReadingWorkerFailure } from '../src/reading/reading-worker-telemetry.js';
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
  const service = new ReadingStagedImageService(
    stagedRepository,
    objects,
    operations,
    clock,
    config,
  );
  return { store, clock, operationRepository, operations, stagedRepository, objects, config, service };
}

async function coffeeOp(h: ReturnType<typeof harness>, owner = 'owner-a') {
  return h.operations.create({
    ownerUserId: owner,
    readingType: 'coffee',
    sourceRequestId: `req-v2-${owner}-${Math.random().toString(36).slice(2)}`,
  });
}

async function palmOp(h: ReturnType<typeof harness>, owner = 'owner-a') {
  return h.operations.create({
    ownerUserId: owner,
    readingType: 'palm',
    sourceRequestId: `req-v2-palm-${owner}-${Math.random().toString(36).slice(2)}`,
  });
}

function stageSlot(
  h: ReturnType<typeof harness>,
  operationId: string,
  slot: (typeof COFFEE_V2_SLOTS)[number],
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

describe('Coffee V2 slot model (pure functions)', () => {
  it('H1 the three canonical slots produce three distinct, deterministic GCS paths', () => {
    const paths = COFFEE_V2_SLOTS.map((slot) =>
      stagedObjectPath({ readingType: 'coffee', ownerUserId: 'owner-a', operationId: 'op-1', ext: 'jpg', slot }),
    );
    expect(new Set(paths).size).toBe(3);
    expect(paths).toEqual([
      'reading-staging/coffee/owner-a/op-1/cup_primary.jpg',
      'reading-staging/coffee/owner-a/op-1/cup_secondary.jpg',
      'reading-staging/coffee/owner-a/op-1/saucer.jpg',
    ]);
    // Distinct from (and never colliding with) the legacy unslotted path.
    const legacy = stagedObjectPath({ readingType: 'coffee', ownerUserId: 'owner-a', operationId: 'op-1', ext: 'jpg' });
    expect(paths).not.toContain(legacy);
    expect(legacy).toBe('reading-staging/coffee/owner-a/op-1/input.jpg');
  });

  it('I1 the three canonical slots produce three distinct Firestore document ids, none equal to the legacy id', () => {
    const ids = COFFEE_V2_SLOTS.map((slot) => stagedDocId('op-1', slot));
    expect(new Set(ids).size).toBe(3);
    expect(ids).toEqual(['op-1--cup_primary', 'op-1--cup_secondary', 'op-1--saucer']);
    expect(ids).not.toContain(stagedDocId('op-1'));
    expect(stagedDocId('op-1')).toBe('op-1');
  });
});

describe('A/B legacy behavior is unchanged when no slot is given', () => {
  it('A legacy Coffee stage (no slot) produces the exact legacy doc id and object path', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    const bytes = fakeJpeg();
    const status = await h.service.stage({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: bytes.toString('base64'),
    });
    expect(status.staged).toBe(true);
    const record = await h.stagedRepository.get(op.operationId, 'owner-a');
    expect(record?.objectPath).toBe(
      stagedObjectPath({ readingType: 'coffee', ownerUserId: 'owner-a', operationId: op.operationId, ext: 'jpg' }),
    );
    expect(record?.slot).toBeUndefined();
    expect(await h.service.hasAnyCoffeeV2Slot({ ownerUserId: 'owner-a', operationId: op.operationId })).toBe(false);
  });

  it('B legacy Palm stage (no slot) is unaffected', async () => {
    const h = harness();
    const op = await palmOp(h);
    const bytes = fakeJpeg();
    const status = await h.service.stage({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: bytes.toString('base64'),
      handSide: 'right',
    });
    expect(status.staged).toBe(true);
    const result = await h.service.retrieveForProcessing({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      readingType: 'palm',
    });
    expect(Buffer.compare(result.bytes, bytes)).toBe(0);
  });
});

describe('C Palm + slot is rejected', () => {
  it('a slot on a Palm operation fails closed', async () => {
    const h = harness();
    const op = await palmOp(h);
    await expect(
      h.service.stage({
        ownerUserId: 'owner-a',
        operationId: op.operationId,
        mimeType: 'image/jpeg',
        imageBase64: fakeJpeg().toString('base64'),
        handSide: 'right',
        slot: 'cup_primary',
      }),
    ).rejects.toBeInstanceOf(ReadingOperationError);
    await expect(
      h.service.stage({
        ownerUserId: 'owner-a',
        operationId: op.operationId,
        mimeType: 'image/jpeg',
        imageBase64: fakeJpeg().toString('base64'),
        handSide: 'right',
        slot: 'cup_primary',
      }),
    ).rejects.toMatchObject({ code: 'invalid' });
  });

  it('an unknown slot value on Coffee also fails closed', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await expect(
      h.service.stage({
        ownerUserId: 'owner-a',
        operationId: op.operationId,
        mimeType: 'image/jpeg',
        imageBase64: fakeJpeg().toString('base64'),
        slot: 'not_a_real_slot',
      }),
    ).rejects.toMatchObject({ code: 'invalid' });
  });
});

describe('D/E/F/G independent slots never overwrite one another', () => {
  it('D cup_primary stages independently', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    const bytes = fakeJpeg(9000);
    await stageSlot(h, op.operationId, 'cup_primary', bytes);
    const record = await h.stagedRepository.getSlot(op.operationId, 'cup_primary', 'owner-a');
    expect(record?.uploadState).toBe('complete');
    expect(record?.byteSize).toBe(bytes.length);
  });

  it('E cup_secondary does not overwrite cup_primary', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    const primary = fakeJpeg(9000);
    const secondary = fakeJpeg(9300);
    await stageSlot(h, op.operationId, 'cup_primary', primary);
    await stageSlot(h, op.operationId, 'cup_secondary', secondary);
    const primaryRecord = await h.stagedRepository.getSlot(op.operationId, 'cup_primary', 'owner-a');
    const secondaryRecord = await h.stagedRepository.getSlot(op.operationId, 'cup_secondary', 'owner-a');
    expect(primaryRecord?.byteSize).toBe(primary.length);
    expect(secondaryRecord?.byteSize).toBe(secondary.length);
    expect(primaryRecord?.objectPath).not.toBe(secondaryRecord?.objectPath);
  });

  it('F saucer does not overwrite either cup slot', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    const primary = fakeJpeg(9000);
    const secondary = fakeJpeg(9300);
    const saucer = fakeJpeg(9600);
    await stageSlot(h, op.operationId, 'cup_primary', primary);
    await stageSlot(h, op.operationId, 'cup_secondary', secondary);
    await stageSlot(h, op.operationId, 'saucer', saucer);
    const [primaryRecord, secondaryRecord, saucerRecord] = await Promise.all([
      h.stagedRepository.getSlot(op.operationId, 'cup_primary', 'owner-a'),
      h.stagedRepository.getSlot(op.operationId, 'cup_secondary', 'owner-a'),
      h.stagedRepository.getSlot(op.operationId, 'saucer', 'owner-a'),
    ]);
    expect(primaryRecord?.byteSize).toBe(primary.length);
    expect(secondaryRecord?.byteSize).toBe(secondary.length);
    expect(saucerRecord?.byteSize).toBe(saucer.length);
    const paths = new Set([primaryRecord?.objectPath, secondaryRecord?.objectPath, saucerRecord?.objectPath]);
    expect(paths.size).toBe(3);
  });

  it('G restaging cup_secondary changes only cup_secondary', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    const primary = fakeJpeg(9000);
    const saucer = fakeJpeg(9600);
    const secondaryV1 = fakeJpeg(9300);
    const secondaryV2 = fakeJpeg(9700);
    await stageSlot(h, op.operationId, 'cup_primary', primary);
    await stageSlot(h, op.operationId, 'saucer', saucer);
    await stageSlot(h, op.operationId, 'cup_secondary', secondaryV1);
    await stageSlot(h, op.operationId, 'cup_secondary', secondaryV2);
    const [primaryRecord, secondaryRecord, saucerRecord] = await Promise.all([
      h.stagedRepository.getSlot(op.operationId, 'cup_primary', 'owner-a'),
      h.stagedRepository.getSlot(op.operationId, 'cup_secondary', 'owner-a'),
      h.stagedRepository.getSlot(op.operationId, 'saucer', 'owner-a'),
    ]);
    expect(primaryRecord?.byteSize).toBe(primary.length);
    expect(saucerRecord?.byteSize).toBe(saucer.length);
    expect(secondaryRecord?.byteSize).toBe(secondaryV2.length);
    // Idempotent restage of the same slot -- exactly one live object for it.
    expect([...h.objects.objects.keys()].filter((p) => p === secondaryRecord?.objectPath)).toHaveLength(1);
  });
});

describe('H/I distinctness proofs against the real service (not just the pure helpers)', () => {
  it('H all three real staged objects live at distinct GCS paths', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await stageSlot(h, op.operationId, 'cup_primary', fakeJpeg(9000));
    await stageSlot(h, op.operationId, 'cup_secondary', fakeJpeg(9100));
    await stageSlot(h, op.operationId, 'saucer', fakeJpeg(9200));
    expect(h.objects.objects.size).toBe(3);
  });

  it('I all three real staged records live at distinct Firestore document identifiers', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await stageSlot(h, op.operationId, 'cup_primary', fakeJpeg(9000));
    await stageSlot(h, op.operationId, 'cup_secondary', fakeJpeg(9100));
    await stageSlot(h, op.operationId, 'saucer', fakeJpeg(9200));
    const legacyDoc = await h.store.docs.get(`readingOperationStagedImages/${op.operationId}`);
    const slots = await h.stagedRepository.listSlots(op.operationId, 'owner-a');
    expect(slots).toHaveLength(3);
    expect(new Set(slots.map((s) => s.objectPath)).size).toBe(3);
    // No legacy (unslotted) document was ever created by slotted staging.
    expect(legacyDoc).toBeUndefined();
    expect(await h.stagedRepository.get(op.operationId, 'owner-a')).toBeNull();
  });
});

describe('J ownership is re-checked for slotted uploads exactly like legacy', () => {
  it('a slotted upload cannot target another owner\'s operation', async () => {
    const h = harness();
    const op = await coffeeOp(h, 'owner-a');
    await expect(
      h.service.stage({
        ownerUserId: 'owner-b',
        operationId: op.operationId,
        mimeType: 'image/jpeg',
        imageBase64: fakeJpeg().toString('base64'),
        slot: 'cup_primary',
      }),
    ).rejects.toMatchObject({ code: 'not_found' });
    expect(await h.stagedRepository.getSlot(op.operationId, 'cup_primary', 'owner-a')).toBeNull();
  });
});

describe('K/L/M/N retrieveCoffeeV2ForProcessing requires the complete canonical set', () => {
  it('K one slot only reports retryable staging-not-ready (never fabricates input)', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await stageSlot(h, op.operationId, 'cup_primary', fakeJpeg());
    await expect(
      h.service.retrieveCoffeeV2ForProcessing({ ownerUserId: 'owner-a', operationId: op.operationId }),
    ).rejects.toMatchObject({ code: 'invalid' });
  });

  it('L two slots only reports retryable staging-not-ready', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await stageSlot(h, op.operationId, 'cup_primary', fakeJpeg(9000));
    await stageSlot(h, op.operationId, 'cup_secondary', fakeJpeg(9100));
    await expect(
      h.service.retrieveCoffeeV2ForProcessing({ ownerUserId: 'owner-a', operationId: op.operationId }),
    ).rejects.toMatchObject({ code: 'invalid' });
  });

  it('M all three complete succeeds, returned in canonical order regardless of upload order', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    const saucer = fakeJpeg(9100);
    const primary = fakeJpeg(9200);
    const secondary = fakeJpeg(9300);
    // Deliberately uploaded out of canonical order.
    await stageSlot(h, op.operationId, 'saucer', saucer);
    await stageSlot(h, op.operationId, 'cup_primary', primary);
    await stageSlot(h, op.operationId, 'cup_secondary', secondary);
    const result = await h.service.retrieveCoffeeV2ForProcessing({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
    });
    expect(result.map((r) => r.slot)).toEqual(['cup_primary', 'cup_secondary', 'saucer']);
    expect(Buffer.compare(result[0]!.bytes, primary)).toBe(0);
    expect(Buffer.compare(result[1]!.bytes, secondary)).toBe(0);
    expect(Buffer.compare(result[2]!.bytes, saucer)).toBe(0);
  });

  it('N one slot left pending (object write failed) reports retryable staging-not-ready', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await stageSlot(h, op.operationId, 'cup_primary', fakeJpeg(9000));
    await stageSlot(h, op.operationId, 'cup_secondary', fakeJpeg(9100));
    const failingObjects = {
      put: async () => {
        throw new Error('simulated gcs failure');
      },
      get: async () => null,
      delete: async () => {},
    };
    const failingService = new ReadingStagedImageService(
      h.stagedRepository,
      failingObjects,
      h.operations,
      h.clock,
      h.config,
    );
    await failingService
      .stage({
        ownerUserId: 'owner-a',
        operationId: op.operationId,
        mimeType: 'image/jpeg',
        imageBase64: fakeJpeg(9200).toString('base64'),
        slot: 'saucer',
      })
      .catch(() => {});
    const saucerRecord = await h.stagedRepository.getSlot(op.operationId, 'saucer', 'owner-a');
    expect(saucerRecord?.uploadState).toBe('pending');
    await expect(
      h.service.retrieveCoffeeV2ForProcessing({ ownerUserId: 'owner-a', operationId: op.operationId }),
    ).rejects.toMatchObject({ code: 'invalid' });
  });
});

describe('O exact-checksum duplicate protection', () => {
  it('rejects a slot whose bytes exactly match an already-complete different slot', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    const shared = fakeJpeg(9000);
    await stageSlot(h, op.operationId, 'cup_primary', shared);
    await expect(stageSlot(h, op.operationId, 'cup_secondary', shared)).rejects.toMatchObject({
      code: 'duplicate_staged_image',
    });
    // The duplicate was never marked complete -- and never could have
    // reached AI/provider execution, since this service has no AI
    // dependency at all (see the R test below for the processor-level proof).
    const secondaryRecord = await h.stagedRepository.getSlot(op.operationId, 'cup_secondary', 'owner-a');
    expect(secondaryRecord).toBeNull();
  });

  it('does not reject restaging the SAME slot with the same bytes (idempotent restage, not a duplicate)', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    const bytes = fakeJpeg(9000);
    await stageSlot(h, op.operationId, 'cup_primary', bytes);
    await expect(stageSlot(h, op.operationId, 'cup_primary', bytes)).resolves.toMatchObject({ staged: true });
  });

  it('does not reject two DIFFERENT slots with different content', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await stageSlot(h, op.operationId, 'cup_primary', fakeJpeg(9000));
    await expect(stageSlot(h, op.operationId, 'cup_secondary', fakeJpeg(9500))).resolves.toMatchObject({
      staged: true,
    });
  });
});

describe('P zero V2 slots + existing legacy Coffee staged image still uses legacy retrieval', () => {
  it('legacy retrieval succeeds and hasAnyCoffeeV2Slot is false', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    const bytes = fakeJpeg();
    await h.service.stage({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: bytes.toString('base64'),
    });
    expect(await h.service.hasAnyCoffeeV2Slot({ ownerUserId: 'owner-a', operationId: op.operationId })).toBe(false);
    const result = await h.service.retrieveForProcessing({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      readingType: 'coffee',
    });
    expect(Buffer.compare(result.bytes, bytes)).toBe(0);
  });
});

describe('R no AI/provider function is called in any partial-slot case (processor-level proof)', () => {
  function processorHarness() {
    const h = harness();
    const ledger = new GemLedger(h.store, h.clock, provisionalGemCostPolicy());
    const flow = new ReadingFlow(h.store, h.clock, h.operations, ledger);
    const results = new ReadingResultRepository(h.store);
    let providerCalls = 0;
    const ai = {
      async handle() {
        providerCalls++;
        return { overall: 'must never be reached', symbols: [], themes: [] };
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
    const owner = identityKeyFromSubject('coffee-v2-durable-user');
    return { ...h, flow, results, processor, owner, providerCalls: () => providerCalls };
  }

  it('one of three slots staged -> process() throws retryable, zero provider calls', async () => {
    const h = processorHarness();
    const op = await h.operations.create({
      ownerUserId: h.owner,
      readingType: 'coffee',
      sourceRequestId: 'coffee-v2-r-01',
    });
    await h.flow.remember(op);
    await stageSlot(h, op.operationId, 'cup_primary', fakeJpeg(), h.owner);
    h.clock.ms = op.readyAtMs;
    await expect(h.processor.process(op.operationId)).rejects.toBeInstanceOf(ReadingWorkerFailure);
    await expect(h.processor.process(op.operationId)).rejects.toMatchObject({ retryable: true });
    expect(h.providerCalls()).toBe(0);
  });

  it('two of three slots staged -> process() throws retryable, zero provider calls', async () => {
    const h = processorHarness();
    const op = await h.operations.create({
      ownerUserId: h.owner,
      readingType: 'coffee',
      sourceRequestId: 'coffee-v2-r-02',
    });
    await h.flow.remember(op);
    await stageSlot(h, op.operationId, 'cup_primary', fakeJpeg(9000), h.owner);
    await stageSlot(h, op.operationId, 'saucer', fakeJpeg(9100), h.owner);
    h.clock.ms = op.readyAtMs;
    await expect(h.processor.process(op.operationId)).rejects.toMatchObject({ retryable: true });
    expect(h.providerCalls()).toBe(0);
  });

  it('legacy single-image Coffee (zero V2 slots) is completely unaffected by the V2 check and still calls the provider exactly once', async () => {
    const h = processorHarness();
    const op = await h.operations.create({
      ownerUserId: h.owner,
      readingType: 'coffee',
      sourceRequestId: 'coffee-v2-r-legacy-01',
    });
    await h.flow.remember(op);
    await h.service.stage({
      ownerUserId: h.owner,
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: fakeJpeg().toString('base64'),
    });
    h.clock.ms = op.readyAtMs;
    expect(await h.processor.process(op.operationId)).toBe('completed');
    expect(h.providerCalls()).toBe(1);
  });
});
