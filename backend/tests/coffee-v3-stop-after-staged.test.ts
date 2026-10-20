/**
 * Coffee V3 stop-after-staged: three real slot reads, zero provider calls.
 * Memory store only. Does not prove GCS.
 */
import { describe, expect, it } from 'vitest';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../src/reading/operation-staged-image-service.js';
import { ReadingFlow } from '../src/reading/reading-flow.js';
import { ReadingProcessor } from '../src/reading/reading-processor.js';
import { ReadingResultRepository } from '../src/reading/reading-result-repository.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
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
const SLOTS = ['v3_cup_view_a', 'v3_cup_view_b', 'v3_saucer_view'] as const;

function harness() {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-10-20T09:00:00Z'));
  const repository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(
    repository,
    clock,
    provisionalWaitPolicy({ coffee: 1000, palm: 1000, soulmate: 1000 }),
  );
  const stagedRepository = new FirestoreReadingStagedImageRepository(store);
  const objects = new MemoryStagedObjectStore();
  const stagedImages = new ReadingStagedImageService(
    stagedRepository,
    objects,
    operations,
    clock,
    testConfig({ READING_STAGING_BUCKET: 'test-bucket', ORACLY_COFFEE_V3_ENABLED: 'true' }),
  );
  const flow = new ReadingFlow(store, clock, operations, new GemLedger(store, clock, provisionalGemCostPolicy()));
  let providerCalls = 0;
  const processor = new ReadingProcessor(
    repository,
    flow,
    stagedRepository,
    stagedImages,
    new ReadingResultRepository(store),
    { async handle() { providerCalls += 1; return { overall: 'should-not-run' }; } },
    clock,
    undefined,
    true,
  );
  return { clock, operations, stagedImages, objects, processor, providerCalls: () => providerCalls, store };
}

describe('coffee v3 stop after staged', () => {
  it('reads the three slots and does not call the provider', async () => {
    const h = harness();
    const op = await h.operations.create({
      ownerUserId: 'owner-qa',
      readingType: 'coffee',
      sourceRequestId: 'qa-stop-v3-01',
      coffeeInputContract: 'trusted_intention_v1',
      coffeeIntention: INTENTION,
      coffeeCaptureContract: 'three_view_v3',
    });
    let n = 0;
    for (const slot of SLOTS) {
      n += 1;
      await h.stagedImages.stage({
        ownerUserId: 'owner-qa',
        operationId: op.operationId,
        mimeType: 'image/jpeg',
        imageBase64: fakeJpeg(12_000 + n).toString('base64'),
        slot,
      });
    }
    h.clock.ms = op.readyAtMs;
    await expect(h.processor.process(op.operationId)).resolves.toBe('staged_ok');
    expect(h.providerCalls()).toBe(0);
    expect(h.objects.objects.size).toBe(3);
  });

  it('a missing slot does not call the provider', async () => {
    const h = harness();
    const op = await h.operations.create({
      ownerUserId: 'owner-qa',
      readingType: 'coffee',
      sourceRequestId: 'qa-stop-v3-missing',
      coffeeInputContract: 'trusted_intention_v1',
      coffeeIntention: INTENTION,
      coffeeCaptureContract: 'three_view_v3',
    });
    await h.stagedImages.stage({
      ownerUserId: 'owner-qa',
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: fakeJpeg(12_100).toString('base64'),
      slot: 'v3_cup_view_a',
    });
    h.clock.ms = op.readyAtMs;
    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    expect(h.providerCalls()).toBe(0);
  });
});
