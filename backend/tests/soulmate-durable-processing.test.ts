import { describe, expect, it, vi } from 'vitest';
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
import { provisionalWaitPolicy, SOULMATE_NO_COMMERCIAL_WAIT_MS } from '../src/reading/wait-policy.js';
import { testConfig } from './helpers.js';
import { FirestoreProviderStageRepository } from '../src/reading/provider-stage-repository.js';
import { FirestoreReadingOperationInputRepository } from '../src/reading/operation-input-repository.js';
import { ReadingOperationInputService } from '../src/reading/operation-input-service.js';
import { GcsSoulmatePortraitStore } from '../src/reading/soulmate-portrait-store.js';
import { InMemorySoulmateEntitlementGuard } from '../src/reading/soulmate-entitlement-guard.js';

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

function harness() {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-09-14T10:00:00Z'));
  const repository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(
    repository,
    clock,
    provisionalWaitPolicy({ soulmate: SOULMATE_NO_COMMERCIAL_WAIT_MS }),
  );
  const ledger = new GemLedger(store, clock, provisionalGemCostPolicy());
  const flow = new ReadingFlow(store, clock, operations, ledger);
  // Soulmate's durable worker never touches the staged-IMAGE path, but
  // ReadingProcessor's constructor still requires these two positionally —
  // unused by the soulmate branch, kept only to satisfy the shared type.
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
  const inputRepository = new FirestoreReadingOperationInputRepository(store);
  const soulmateInputs = new ReadingOperationInputService(inputRepository, operations, clock);
  const portraitObjects = new MemoryStagedObjectStore();
  const soulmatePortraits = new GcsSoulmatePortraitStore(portraitObjects, store);
  const entitlement = new InMemorySoulmateEntitlementGuard();

  let portraitCalls = 0;
  let interpretationCalls = 0;
  let failPortrait = false;
  let failInterpretation = false;
  let portraitBytes = fakePng('fake-portrait-bytes');
  const ai = {
    async handle(request: { operation: string }) {
      if (request.operation === 'soulmate_draw') {
        portraitCalls++;
        if (failPortrait) throw new Error('transient_provider_failure');
        return {
          imageBase64: portraitBytes.toString('base64'),
          mimeType: 'image/png',
          identity: { archetype: 'the-wanderer' },
        };
      }
      if (request.operation === 'soulmate_interpretation') {
        interpretationCalls++;
        if (failInterpretation) throw new Error('transient_provider_failure');
        return {
          personality: 'durable personality',
          dynamic: 'durable dynamic',
          attraction: 'durable attraction',
          challenge: 'durable challenge',
          meeting: 'durable meeting',
          feeling: 'durable feeling',
        };
      }
      throw new Error(`unexpected_operation_${request.operation}`);
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
    undefined,
    soulmateInputs,
    soulmatePortraits,
    entitlement,
  );

  const owner = identityKeyFromSubject('durable-soulmate-user');

  async function createDurable(sourceRequestId = 'soulmate-durable-01') {
    const operation = await operations.create({
      ownerUserId: owner,
      readingType: 'soulmate',
      sourceRequestId,
      executionMode: 'durable',
    });
    await flow.remember(operation);
    await soulmateInputs.save({
      ownerUserId: owner,
      operationId: operation.operationId,
      fields: { name: 'Ada', birthIso: '1995-03-02', gender: 'feminine', intention: 'long-term' },
    });
    // Mirrors production: the Cloud Task that actually invokes process() is
    // scheduled at operation.readyAtMs (see reading-operation-input-routes.ts),
    // so by the time it fires the wait has already elapsed.
    clock.ms = operation.readyAtMs;
    return operation;
  }

  async function createLegacy(sourceRequestId = 'soulmate-legacy-01') {
    const operation = await operations.create({
      ownerUserId: owner,
      readingType: 'soulmate',
      sourceRequestId,
    });
    await flow.remember(operation);
    clock.ms = operation.readyAtMs;
    return operation;
  }

  return {
    store, clock, repository, operations, ledger, flow, results, notifier,
    processor, owner, providerStages, soulmatePortraits, portraitObjects, entitlement,
    createDurable, createLegacy,
    portraitCalls: () => portraitCalls,
    interpretationCalls: () => interpretationCalls,
    setPortraitFailure: (value: boolean) => { failPortrait = value; },
    setInterpretationFailure: (value: boolean) => { failInterpretation = value; },
    setPortraitBytes: (value: Buffer) => { portraitBytes = value; },
  };
}

function fakePng(label: string): Buffer {
  const bytes = Buffer.alloc(96);
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]).copy(bytes);
  Buffer.from(label).copy(bytes, 8);
  return bytes;
}

const identity = { archetype: 'the-sage' } as never;

describe('SMD1 soulmate durable worker', () => {
  it('completes end-to-end: one portrait call, one interpretation call, portrait persisted, result ready', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const operation = await h.createDurable();

    expect(await h.processor.process(operation.operationId)).toBe('completed');

    expect((await h.repository.getById(operation.operationId))?.status).toBe('ready');
    expect(h.portraitCalls()).toBe(1);
    expect(h.interpretationCalls()).toBe(1);
    expect(h.notifier.calls).toBe(1);

    const portrait = await h.soulmatePortraits.get(operation.operationId, h.owner);
    expect(portrait?.contentType).toBe('image/png');
    expect(portrait?.bytes.equals(fakePng('fake-portrait-bytes'))).toBe(true);

    const result = await h.results.get(operation.operationId);
    expect(result?.data.personality).toBe('durable personality');

    expect(await h.processor.process(operation.operationId)).toBe('noop');
    expect(h.portraitCalls()).toBe(1);
    expect(h.interpretationCalls()).toBe(1);
  });

  it('R2.1 — a pre-existing notification claim (simulated crash/redelivery boundary) blocks any FCM call for this run', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const operation = await h.createDurable();
    // Simulate a redelivered/racing worker invocation that already won
    // the durable dispatch claim before THIS run started (e.g. a
    // lease-expiry race, or a crash between the claim and the actual FCM
    // call on a previous attempt).
    await h.results.persistOnce({
      schemaVersion: 1,
      operationId: operation.operationId,
      ownerUserId: h.owner,
      readingType: 'soulmate',
      resultId: `soulmate_${operation.operationId}`,
      data: {
        personality: 'durable personality',
        dynamic: 'durable dynamic',
        attraction: 'durable attraction',
        challenge: 'durable challenge',
        meeting: 'durable meeting',
        feeling: 'durable feeling',
        identity: { archetype: 'the-wanderer' },
        portraitAvailable: true,
      },
      persistedAtMs: h.clock.ms,
      notificationSentAtMs: null,
    });
    await h.results.claimNotificationDispatch(operation.operationId, h.clock.ms);

    expect(await h.processor.process(operation.operationId)).toBe('completed');
    expect(h.notifier.calls).toBe(0);
    expect((await h.repository.getById(operation.operationId))?.status).toBe('ready');
  });

  it('worker retry after the portrait checkpoint keeps the portrait attempt count at exactly 1', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const operation = await h.createDurable();
    h.setInterpretationFailure(true);

    // Exactly-once cannot be guaranteed (SMD1 §5): a failure during the
    // interpretation call itself leaves that checkpoint ambiguous
    // (in_flight), so the SAME retry rules that protect the portrait stage
    // also apply to interpretation — the correct, safe outcome on retry is
    // a final failure, never a silent second portrait charge.
    await expect(h.processor.process(operation.operationId)).rejects.toThrow('transient');
    expect(h.portraitCalls()).toBe(1);
    expect(h.interpretationCalls()).toBe(1);
    // Portrait must already be durably persisted before interpretation ran.
    const portraitAfterFailure = await h.soulmatePortraits.get(operation.operationId, h.owner);
    expect(portraitAfterFailure).not.toBeNull();

    h.setInterpretationFailure(false);
    expect(await h.processor.process(operation.operationId)).toBe('failed');

    // The single most safety-critical invariant: the portrait provider is
    // NEVER called a second time, no matter how many times interpretation
    // is retried or how it fails.
    expect(h.portraitCalls()).toBe(1);
    // The ambiguous in-flight interpretation checkpoint blocks a resend too
    // — ai.handle for interpretation is not invoked again either.
    expect(h.interpretationCalls()).toBe(1);
    expect((await h.repository.getById(operation.operationId))?.status).toBe('failed');
  });

  it('app killed after portrait success before interpretation: re-run does not re-call the portrait provider', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const operation = await h.createDurable();
    // Simulate the process dying right after the portrait checkpoint by
    // pre-seeding the exact checkpoint state the worker would have reached.
    await h.soulmatePortraits.put({
      operationId: operation.operationId,
      ownerUserId: h.owner,
      bytes: fakePng('pre-seeded-portrait'),
      contentType: 'image/png',
      identity,
    });

    expect(await h.processor.process(operation.operationId)).toBe('completed');
    expect(h.portraitCalls()).toBe(0);
    expect(h.interpretationCalls()).toBe(1);
    expect((await h.repository.getById(operation.operationId))?.status).toBe('ready');
  });

  it('a legacy (executionMode absent) soulmate operation is never touched by the durable worker', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const operation = await h.createLegacy();

    expect(await h.processor.process(operation.operationId)).toBe('noop');
    expect(h.portraitCalls()).toBe(0);
    expect(h.interpretationCalls()).toBe(0);
    expect((await h.repository.getById(operation.operationId))?.status).toBe('waiting');
  });

  it('Premium not active: fails closed before any provider call', async () => {
    const h = harness();
    const operation = await h.createDurable();
    // entitlement never granted for this owner

    expect(await h.processor.process(operation.operationId)).toBe('failed');
    expect(h.portraitCalls()).toBe(0);
    expect(h.interpretationCalls()).toBe(0);
    expect((await h.repository.getById(operation.operationId))?.status).toBe('failed');
  });

  it('ambiguous portrait outcome never triggers a second paid call and fails final', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const operation = await h.createDurable();
    await h.providerStages.markInFlight(`${operation.operationId}:portrait`, h.owner);

    expect(await h.processor.process(operation.operationId)).toBe('failed');
    expect(h.portraitCalls()).toBe(0);
    expect(h.interpretationCalls()).toBe(0);
    expect((await h.providerStages.get(`${operation.operationId}:portrait`)).state).toBe(
      'provider_outcome_unknown',
    );
    expect((await h.repository.getById(operation.operationId))?.status).toBe('failed');
  });

  it('duplicate worker/task delivery (concurrent process()) results in exactly one portrait call', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const operation = await h.createDurable();

    const outcomes = await Promise.allSettled([
      h.processor.process(operation.operationId),
      h.processor.process(operation.operationId),
    ]);
    expect(outcomes.filter((o) => o.status === 'fulfilled')).toHaveLength(1);
    expect(h.portraitCalls()).toBe(1);
    expect(h.interpretationCalls()).toBe(1);
    expect(await h.processor.process(operation.operationId)).toBe('noop');
    expect(h.notifier.calls).toBe(1);
  });

  it('active processing lease blocks reclaim until expiry, then resumes the same operation', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const operation = await h.createDurable();
    const claimed = await h.flow.claim(h.owner, operation.operationId);
    expect(claimed.execute).toBe(true);

    await expect(h.processor.process(operation.operationId)).rejects.toThrow(
      'processing_lease_active',
    );
    expect(h.portraitCalls()).toBe(0);

    h.clock.ms += PROCESSING_LEASE_MS + 1;
    await expect(h.processor.process(operation.operationId)).resolves.toBe('completed');
    expect(h.portraitCalls()).toBe(1);
  });

  it('result-persistence failure path reuses checkpointed portrait and interpretation without regenerating either', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const operation = await h.createDurable();
    // Force both stages already checkpointed/persisted, as if the worker
    // reached result-persistence and died before ReadingFlow.complete().
    await h.soulmatePortraits.put({
      operationId: operation.operationId,
      ownerUserId: h.owner,
      bytes: fakePng('fake-portrait-bytes'),
      contentType: 'image/png',
      identity,
    });
    await h.providerStages.markCompleted(`${operation.operationId}:interpretation`, h.owner, {
      personality: 'durable personality',
      dynamic: 'durable dynamic',
      attraction: 'durable attraction',
      challenge: 'durable challenge',
      meeting: 'durable meeting',
      feeling: 'durable feeling',
    });

    expect(await h.processor.process(operation.operationId)).toBe('completed');
    expect(h.portraitCalls()).toBe(0);
    expect(h.interpretationCalls()).toBe(0);
    expect((await h.repository.getById(operation.operationId))?.status).toBe('ready');
  });

  it('notification failure never changes an already-persisted soulmate result to failed', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const operation = await h.createDurable();
    h.notifier.fail = true;

    await expect(h.processor.process(operation.operationId)).resolves.toBe('completed');
    expect((await h.repository.getById(operation.operationId))?.status).toBe('ready');
    expect(await h.results.get(operation.operationId)).not.toBeNull();
  });

  it('Coffee/Palm durable path is unaffected by the soulmate branch (soulmate-only wiring untouched)', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const operation = await h.operations.create({
      ownerUserId: h.owner,
      readingType: 'palm',
      sourceRequestId: 'palm-unaffected-01',
    });
    await h.flow.remember(operation);
    // Clock is untouched (still before this palm operation's own readyAtMs)
    // and it was never accelerated, so claim() legitimately returns
    // execute:false — the point of this test is only that the new
    // soulmate branch in ReadingProcessor.process() does not intercept or
    // short-circuit a non-soulmate readingType before reaching that check.
    expect(await h.processor.process(operation.operationId)).toBe('noop');
    expect(h.portraitCalls()).toBe(0);
    expect(h.interpretationCalls()).toBe(0);
  });

  it('stores only a compact portrait checkpoint and never raw imageBase64', async () => {
    const h = harness(); h.entitlement.grant(h.owner);
    const operation = await h.createDurable('compact-checkpoint');
    const largePortrait = Buffer.alloc(300 * 1024);
    fakePng('large-provider-portrait').subarray(0, 32).copy(largePortrait);
    h.setPortraitBytes(largePortrait);
    expect(await h.processor.process(operation.operationId)).toBe('completed');
    const stage = await h.providerStages.get(`${operation.operationId}:portrait`);
    expect(stage.state).toBe('persisted');
    expect(stage.output).toMatchObject({ operation: 'soulmate_draw', artifact: { contentType: 'image/png', byteSize: largePortrait.length } });
    expect(JSON.stringify(stage.output)).not.toContain('imageBase64');
    expect(JSON.stringify(stage.output)).not.toContain(largePortrait.toString('base64'));
  });

  it('recovers a verified artifact when compact checkpointing fails, without a second paid call', async () => {
    const h = harness(); h.entitlement.grant(h.owner);
    const operation = await h.createDurable('checkpoint-failure-recovery');
    vi.spyOn(h.providerStages, 'markCompleted').mockRejectedValueOnce(new Error('firestore_invalid_argument'));
    await expect(h.processor.process(operation.operationId)).rejects.toThrow('firestore_invalid_argument');
    expect(h.portraitCalls()).toBe(1);
    expect(await h.soulmatePortraits.get(operation.operationId, h.owner)).not.toBeNull();
    expect(await h.processor.process(operation.operationId)).toBe('completed');
    expect(h.portraitCalls()).toBe(1);
    expect(h.interpretationCalls()).toBe(1);
  });

  it('fails closed after pre-durability storage failure and never retries the paid call', async () => {
    const h = harness(); h.entitlement.grant(h.owner);
    const operation = await h.createDurable('storage-failure');
    vi.spyOn(h.soulmatePortraits, 'put').mockRejectedValueOnce(new Error('gcs_unavailable'));
    await expect(h.processor.process(operation.operationId)).rejects.toThrow('gcs_unavailable');
    expect(h.portraitCalls()).toBe(1);
    expect(await h.processor.process(operation.operationId)).toBe('failed');
    expect(h.portraitCalls()).toBe(1);
    expect(h.interpretationCalls()).toBe(0);
  });

  it('does not recover a corrupted artifact and still never repeats the paid call', async () => {
    const h = harness(); h.entitlement.grant(h.owner);
    const operation = await h.createDurable('corrupt-artifact');
    vi.spyOn(h.providerStages, 'markCompleted').mockRejectedValueOnce(new Error('checkpoint_failed'));
    await expect(h.processor.process(operation.operationId)).rejects.toThrow('checkpoint_failed');
    const [path] = h.portraitObjects.objects.keys();
    h.portraitObjects.objects.set(path, { bytes: fakePng('tampered'), contentType: 'image/png' });
    expect(await h.processor.process(operation.operationId)).toBe('failed');
    expect(h.portraitCalls()).toBe(1);
  });

  it('portrait ownership mismatch is indistinguishable from not found', async () => {
    const h = harness(); h.entitlement.grant(h.owner);
    const operation = await h.createDurable('owner-isolation');
    expect(await h.processor.process(operation.operationId)).toBe('completed');
    expect(await h.soulmatePortraits.get(operation.operationId, 'different-owner')).toBeNull();
    expect(await h.soulmatePortraits.get('missing-operation', 'different-owner')).toBeNull();
  });
});
