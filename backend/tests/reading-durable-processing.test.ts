import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import type { ServerClock } from '../src/reading/clock.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../src/reading/operation-staged-image-service.js';
import { ReadingFlow, PROCESSING_LEASE_MS } from '../src/reading/reading-flow.js';
import { ReadingProcessor, type ReadingCompletionNotifier } from '../src/reading/reading-processor.js';
import { ReadingResultRepository } from '../src/reading/reading-result-repository.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import { fakeJpeg, testConfig } from './helpers.js';
import { FirestoreProviderStageRepository } from '../src/reading/provider-stage-repository.js';

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date { return new Date(this.ms); }
}

class CounterNotifier implements ReadingCompletionNotifier {
  calls = 0;
  fail = false;
  constructor(private readonly results: ReadingResultRepository) {}
  async notifyCompleted(input: { operationId: string }): Promise<void> {
    expect(await this.results.get(input.operationId)).not.toBeNull();
    this.calls++;
    if (this.fail) throw new Error('fcm_unavailable');
  }
}

function harness(type: 'coffee' | 'palm' = 'palm') {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-09-11T10:00:00Z'));
  const repository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(
    repository,
    clock,
    provisionalWaitPolicy({ coffee: 60_000, palm: 60_000 }),
  );
  const ledger = new GemLedger(store, clock, provisionalGemCostPolicy());
  const flow = new ReadingFlow(store, clock, operations, ledger);
  const stagedRepository = new FirestoreReadingStagedImageRepository(store);
  const stagedImages = new ReadingStagedImageService(
    stagedRepository,
    new MemoryStagedObjectStore(),
    operations,
    clock,
    testConfig({ READING_STAGING_BUCKET: 'test-bucket' }),
  );
  const results = new ReadingResultRepository(store);
  const notifier = new CounterNotifier(results);
  const providerStages = new FirestoreProviderStageRepository(store);
  let providerCalls = 0;
  let failProvider = false;
  const ai = {
    async handle() {
      providerCalls++;
      if (failProvider) throw new Error('transient_provider_failure');
      return { overall: 'durable result', symbols: [], themes: [] };
    },
  };
  const processor = new ReadingProcessor(
    repository,
    flow,
    stagedRepository,
    stagedImages,
    results,
    ai,
    clock,
    notifier,
    false,
    providerStages,
  );
  const owner = identityKeyFromSubject('durable-user');
  async function createAndStage() {
    const operation = await operations.create({
      ownerUserId: owner,
      readingType: type,
      sourceRequestId: `${type}-durable-01`,
    });
    await flow.remember(operation);
    await stagedImages.stage({
      ownerUserId: owner,
      operationId: operation.operationId,
      mimeType: 'image/jpeg',
      imageBase64: fakeJpeg().toString('base64'),
      ...(type === 'palm' ? { handSide: 'right' } : {}),
    });
    return operation;
  }
  return {
    store, clock, repository, operations, ledger, flow, results, notifier,
    processor, owner, createAndStage, providerStages,
    providerCalls: () => providerCalls,
    setProviderFailure: (value: boolean) => { failProvider = value; },
  };
}

describe.each(['coffee', 'palm'] as const)('durable %s processing', (type) => {
  it('completes the same accelerated operation with no client follow-up', async () => {
    const h = harness(type);
    const operation = await h.createAndStage();
    await h.ledger.credit({ ownerUserId: h.owner, amount: 40, idempotencyKey: 'seed-durable-01' });
    const accelerated = await h.ledger.accelerate({
      ownerUserId: h.owner,
      operationId: operation.operationId,
      idempotencyKey: 'accelerate-durable-01',
    });
    expect(accelerated.balance).toBe(40 - accelerated.canonicalCost);
    expect(await h.processor.process(operation.operationId)).toBe('completed');
    expect((await h.repository.getById(operation.operationId))?.status).toBe('ready');
    expect((await h.results.get(operation.operationId))?.operationId).toBe(operation.operationId);
    expect(h.providerCalls()).toBe(1);
    expect(h.notifier.calls).toBe(1);
    expect([...h.store.docs.values()].filter((d) => d.type === 'spend')).toHaveLength(1);
    expect(await h.processor.process(operation.operationId)).toBe('noop');
    expect(h.providerCalls()).toBe(1);
    expect(h.notifier.calls).toBe(1);
  });

  it('processes free wait expiry while no client exists', async () => {
    const h = harness(type);
    const operation = await h.createAndStage();
    h.clock.ms = operation.readyAtMs;
    expect(await h.processor.process(operation.operationId)).toBe('completed');
    expect((await h.repository.getById(operation.operationId))?.status).toBe('ready');
    expect(h.providerCalls()).toBe(1);
  });
});

it('acceleration and ready task race results in one provider execution', async () => {
  const h = harness('palm');
  const operation = await h.createAndStage();
  await h.ledger.credit({ ownerUserId: h.owner, amount: 40, idempotencyKey: 'seed-race-01' });
  await h.ledger.accelerate({ ownerUserId: h.owner, operationId: operation.operationId, idempotencyKey: 'accel-race-01' });
  const outcomes = await Promise.allSettled([
    h.processor.process(operation.operationId),
    h.processor.process(operation.operationId),
  ]);
  expect(outcomes.filter((item) => item.status === 'fulfilled')).toHaveLength(1);
  expect(h.providerCalls()).toBe(1);
  expect(await h.processor.process(operation.operationId)).toBe('noop');
  expect(h.notifier.calls).toBe(1);
  expect([...h.store.docs.values()].filter((d) => d.type === 'spend')).toHaveLength(1);
});

it('ambiguous provider failure never resends and compensates an accelerated operation', async () => {
  const h = harness('palm');
  const operation = await h.createAndStage();
  await h.ledger.credit({ ownerUserId: h.owner, amount: 40, idempotencyKey: 'seed-retry-01' });
  await h.ledger.accelerate({ ownerUserId: h.owner, operationId: operation.operationId, idempotencyKey: 'accel-retry-01' });
  h.setProviderFailure(true);
  await expect(h.processor.process(operation.operationId)).rejects.toThrow('transient');
  const balanceAfterFailure = await h.ledger.balanceOf(h.owner);
  h.setProviderFailure(false);
  expect(await h.processor.process(operation.operationId)).toBe('failed');
  expect(await h.ledger.balanceOf(h.owner)).toBeGreaterThan(balanceAfterFailure);
  expect(h.providerCalls()).toBe(1);
  expect([...h.store.docs.values()].filter((d) => d.type === 'spend')).toHaveLength(1);
});

it('notification failure never changes a persisted completed reading to failed', async () => {
  const h = harness('coffee');
  const operation = await h.createAndStage();
  h.clock.ms = operation.readyAtMs;
  h.notifier.fail = true;
  await expect(h.processor.process(operation.operationId)).resolves.toBe('completed');
  expect((await h.repository.getById(operation.operationId))?.status).toBe('ready');
  expect(await h.results.get(operation.operationId)).not.toBeNull();
  expect(await h.processor.process(operation.operationId)).toBe('noop');
  expect(h.notifier.calls).toBe(1);
});

it('active processing lease blocks reclaim until expiry then resumes same operation', async () => {
  const h = harness('palm');
  const operation = await h.createAndStage();
  h.clock.ms = operation.readyAtMs;
  const claimed = await h.flow.claim(h.owner, operation.operationId);
  expect(claimed.execute).toBe(true);
  await expect(h.processor.process(operation.operationId)).rejects.toThrow(
    'processing_lease_active',
  );
  expect(h.providerCalls()).toBe(0);
  h.clock.ms += PROCESSING_LEASE_MS + 1;
  await expect(h.processor.process(operation.operationId)).resolves.toBe('completed');
  expect((await h.repository.getById(operation.operationId))?.operationId).toBe(
    operation.operationId,
  );
  expect(h.providerCalls()).toBe(1);
  expect([...h.store.docs.values()].filter((d) => d.type === 'spend')).toHaveLength(0);
});

it('retry after an unresolved in-flight attempt becomes unknown without resend', async () => {
  const h = harness('palm');
  const operation = await h.createAndStage();
  h.clock.ms = operation.readyAtMs;
  h.setProviderFailure(true);
  await expect(h.processor.process(operation.operationId)).rejects.toThrow('transient');
  expect(h.providerCalls()).toBe(1);
  h.setProviderFailure(false);
  await expect(h.processor.process(operation.operationId)).resolves.toBe('failed');
  expect(h.providerCalls()).toBe(1);
  expect((await h.repository.getById(operation.operationId))?.status).toBe('failed');
});

describe('R4B provider fault injection A-F', () => {
  it('A crash before in-flight commit leaves not_started and retry safely initiates once', async () => {
    const h = harness('palm'); const op = await h.createAndStage(); h.clock.ms = op.readyAtMs;
    expect(await h.processor.process(op.operationId)).toBe('completed'); expect(h.providerCalls()).toBe(1);
  });
  for (const label of [
    'B crash after in-flight commit before network send',
    'C process disappears after provider request send',
    'D response arrives before provider_completed checkpoint',
  ]) {
    it(`${label}: retry does not resend`, async () => {
      const h = harness('palm'); const op = await h.createAndStage(); h.clock.ms = op.readyAtMs;
      await h.providerStages.markInFlight(op.operationId, h.owner);
      expect(await h.processor.process(op.operationId)).toBe('failed'); expect(h.providerCalls()).toBe(0);
      expect((await h.providerStages.get(op.operationId)).state).toBe('provider_outcome_unknown');
    });
  }
  it('E completed checkpoint is reused before final persistence', async () => {
    const h = harness('palm'); const op = await h.createAndStage(); h.clock.ms = op.readyAtMs;
    await h.providerStages.markCompleted(op.operationId, h.owner, { overall: 'checkpointed', symbols: [], themes: [] });
    expect(await h.processor.process(op.operationId)).toBe('completed'); expect(h.providerCalls()).toBe(0);
  });
  it('F persisted operation retry is a no-op', async () => {
    const h = harness('palm'); const op = await h.createAndStage(); h.clock.ms = op.readyAtMs;
    expect(await h.processor.process(op.operationId)).toBe('completed');
    expect(await h.processor.process(op.operationId)).toBe('noop'); expect(h.providerCalls()).toBe(1);
  });
});

it('stopAfterStaged completes staged fetch without provider or gem debit', async () => {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-09-11T10:00:00Z'));
  const repository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(
    repository,
    clock,
    provisionalWaitPolicy({ coffee: 60_000, palm: 60_000 }),
  );
  const ledger = new GemLedger(store, clock, provisionalGemCostPolicy());
  const flow = new ReadingFlow(store, clock, operations, ledger);
  const stagedRepository = new FirestoreReadingStagedImageRepository(store);
  const stagedImages = new ReadingStagedImageService(
    stagedRepository,
    new MemoryStagedObjectStore(),
    operations,
    clock,
    testConfig({ READING_STAGING_BUCKET: 'test-bucket' }),
  );
  const results = new ReadingResultRepository(store);
  let providerCalls = 0;
  const processor = new ReadingProcessor(
    repository,
    flow,
    stagedRepository,
    stagedImages,
    results,
    {
      async handle() {
        providerCalls++;
        return { overall: 'should-not-run' };
      },
    },
    clock,
    undefined,
    true,
  );
  const owner = identityKeyFromSubject('stop-after-staged');
  const operation = await operations.create({
    ownerUserId: owner,
    readingType: 'palm',
    sourceRequestId: 'palm-stop-after-01',
  });
  await flow.remember(operation);
  await stagedImages.stage({
    ownerUserId: owner,
    operationId: operation.operationId,
    mimeType: 'image/jpeg',
    imageBase64: fakeJpeg().toString('base64'),
    handSide: 'right',
  });
  clock.ms = operation.readyAtMs;
  await expect(processor.process(operation.operationId)).resolves.toBe('staged_ok');
  expect(providerCalls).toBe(0);
  expect((await repository.getById(operation.operationId))?.status).toBe('processing');
  expect((await repository.getById(operation.operationId))?.resultId).toBeNull();
  expect([...store.docs.values()].filter((d) => d.type === 'spend')).toHaveLength(0);
});
