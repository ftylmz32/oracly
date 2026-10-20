import { describe, expect, it } from 'vitest';
import { ErrorCode, ProxyError } from '../src/errors.js';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
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

describe('spend guard refund', () => {
  it('fails the operation and returns the gem debit without calling twice', async () => {
    const store = new MemoryDocumentStore();
    const clock = new FixedClock(Date.parse('2026-10-20T09:00:00Z'));
    const repository = new FirestoreReadingOperationRepository(store);
    const operations = new ReadingOperationService(
      repository,
      clock,
      provisionalWaitPolicy({ coffee: 1000, palm: 1000, soulmate: 1000 }),
    );
    const owner = identityKeyFromSubject('spend-guard-owner');
    const ledger = new GemLedger(store, clock, provisionalGemCostPolicy());
    await ledger.credit({ ownerUserId: owner, amount: 40, idempotencyKey: 'seed-spend-guard' });
    const op = await operations.create({
      ownerUserId: owner,
      readingType: 'coffee',
      sourceRequestId: 'spend-guard-01',
    });
    const stagedImages = new ReadingStagedImageService(
      new FirestoreReadingStagedImageRepository(store),
      new MemoryStagedObjectStore(),
      operations,
      clock,
      testConfig({ READING_STAGING_BUCKET: 'test-bucket' }),
    );
    await stagedImages.stage({
      ownerUserId: owner,
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: fakeJpeg(12_000).toString('base64'),
    });
    await ledger.accelerate({
      ownerUserId: owner,
      operationId: op.operationId,
      idempotencyKey: 'spend-guard-accel',
    });
    expect(await ledger.balanceOf(owner)).toBeLessThan(40);
    await repository.mutate(op.operationId, owner, (current) => ({
      ...current,
      executionStartedAtMs: clock.ms - 13 * 60 * 1000,
    }));
    let calls = 0;
    const processor = new ReadingProcessor(
      repository,
      new ReadingFlow(store, clock, operations, ledger),
      new FirestoreReadingStagedImageRepository(store),
      stagedImages,
      new ReadingResultRepository(store),
      { async handle() { calls += 1; throw new ProxyError(ErrorCode.spendGuard, 503); } },
      clock,
    );
    await expect(processor.process(op.operationId)).resolves.toBe('failed');
    expect(calls).toBe(1);
    expect(await ledger.balanceOf(owner)).toBe(40);
    expect((await operations.get(owner, op.operationId)).status).toBe('failed');
  });
});
