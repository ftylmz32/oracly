import { describe, expect, it } from 'vitest';
import type { Firestore } from '@google-cloud/firestore';
import type { Storage } from '@google-cloud/storage';
import { FirestoreAccountDeletionRepository } from '../src/account/account-deletion.js';
import { accountDeletionReceiptId } from '../src/account/deletion-barrier.js';
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
import { ReadingFlow } from '../src/reading/reading-flow.js';
import { ReadingProcessor } from '../src/reading/reading-processor.js';
import { ReadingResultRepository } from '../src/reading/reading-result-repository.js';
import { provisionalWaitPolicy, SOULMATE_NO_COMMERCIAL_WAIT_MS } from '../src/reading/wait-policy.js';
import { FirestoreProviderStageRepository } from '../src/reading/provider-stage-repository.js';
import { FirestoreReadingOperationInputRepository } from '../src/reading/operation-input-repository.js';
import { ReadingOperationInputService } from '../src/reading/operation-input-service.js';
import { GcsSoulmatePortraitStore } from '../src/reading/soulmate-portrait-store.js';
import { InMemorySoulmateEntitlementGuard } from '../src/reading/soulmate-entitlement-guard.js';
import { fakeJpeg, testConfig } from './helpers.js';

/**
 * WAVE 3.1 — ACCOUNT DELETION x IN-FLIGHT SERVER WORKER (RED GATE).
 *
 * Contract: once `deleteForIdentity(owner)` has returned, NO late worker
 * mutation may recreate any owner-scoped state (provider stage, reading
 * result, Soulmate portrait metadata, Soulmate portrait object).
 *
 * The REAL `FirestoreAccountDeletionRepository` runs unmodified; only its
 * transport is adapted onto the SAME `MemoryDocumentStore` (and the SAME
 * object store) the real durable worker writes to, so a late write and the
 * deletion sweep observe one shared storage state. The provider is latched
 * so deletion can be interleaved deterministically while the worker is
 * parked inside `ai.handle`.
 *
 * Scenarios A/B were RED before WAVE 3.2 (no server-side barrier; the late
 * worker re-created result / provider stage / portrait meta + object). WAVE
 * 3.2 writes the deletion barrier first and gates every creating write on it,
 * so all scenarios, guards A-F and the barrier/write-path tests are GREEN.
 * Scope is strictly in-flight worker x deletion — no auth /
 * token-revocation route behavior is exercised here.
 */

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date { return new Date(this.ms); }
}

type Deferred = { promise: Promise<void>; resolve: () => void };
function deferred(): Deferred {
  let resolve!: () => void;
  const promise = new Promise<void>((r) => { resolve = r; });
  return { promise, resolve };
}
type Latch = { entered: Deferred; release: Deferred };

/** Test-only Firestore transport for the real deletion repository, backed by
 * the worker's own MemoryDocumentStore. Every mutation goes through the
 * store's transaction queue and is recorded in order in `events`. */
class DeletionFirestoreAdapter {
  readonly events: string[] = [];
  /** receipt existence observed at the moment of the FIRST destructive op. */
  receiptExistedAtFirstDestructiveOp: boolean | null = null;

  constructor(private readonly store: MemoryDocumentStore) {}

  noteDestructive(label: string): void {
    if (this.receiptExistedAtFirstDestructiveOp === null) {
      this.receiptExistedAtFirstDestructiveOp = [...this.store.docs.keys()]
        .some((path) => path.startsWith('accountDeletionReceipts/'));
    }
    this.events.push(label);
  }

  collection(name: string) {
    const store = this.store;
    const self = this;
    return {
      doc(id: string) {
        const ref = store.collection(name).doc(id);
        return {
          path: `${name}/${id}`,
          get: () => ref.get(),
          async set(data: Record<string, unknown>) {
            self.events.push(`set:${name}`);
            await store.runTransaction(async (tx) => { tx.set(ref, data); });
          },
        };
      },
      where(field: string, _op: string, value: unknown) {
        return {
          async get() {
            const docs = [...store.docs.entries()]
              .filter(([path]) => path.startsWith(`${name}/`))
              .filter(([, data]) => data[field] === value)
              .map(([path, data]) => ({
                ref: store.collection(name).doc(path.slice(name.length + 1)),
                data: () => ({ ...data }),
              }));
            return { docs, empty: docs.length === 0, size: docs.length };
          },
        };
      },
    };
  }

  batch() {
    const refs: unknown[] = [];
    const self = this;
    return {
      delete(ref: unknown) { refs.push(ref); },
      async commit() {
        const collections = [...new Set(refs.map((r) => String((r as { path: string }).path).split('/')[0]))];
        self.noteDestructive(`delete:${collections.join(',')}:${refs.length}`);
        await self.store.runTransaction(async (tx) => {
          for (const ref of refs) tx.delete(ref as never);
        });
      },
    };
  }

  runTransaction<T>(fn: (tx: never) => Promise<T>): Promise<T> {
    return this.store.runTransaction(fn as never);
  }
}

/** Test-only GCS transport: the same bucket holds staged inputs AND
 * Soulmate portraits in production, so one object store backs both. */
function storageFake(objects: MemoryStagedObjectStore, adapter: DeletionFirestoreAdapter) {
  return {
    bucket: (_name: string) => ({
      file: (path: string) => ({
        async delete() {
          adapter.noteDestructive(`object:${path.split('/')[0]}`);
          objects.objects.delete(path);
        },
      }),
    }),
  };
}

function fakePng(label: string): Buffer {
  const bytes = Buffer.alloc(96);
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]).copy(bytes);
  Buffer.from(label).copy(bytes, 8);
  return bytes;
}

/** Object store with an interleaving seam right after a successful upload
 * (the window between the GCS put and the metadata transaction). */
class HookedObjectStore extends MemoryStagedObjectStore {
  readonly puts: string[] = [];
  afterPut: ((path: string) => Promise<void>) | null = null;
  override async put(objectPath: string, bytes: Buffer, contentType: string): Promise<void> {
    this.puts.push(objectPath);
    await super.put(objectPath, bytes, contentType);
    if (this.afterPut) await this.afterPut(objectPath);
  }
}

/** Provider-stage repository with an interleaving seam right before a claim
 * (e.g. between the Soulmate portrait and interpretation stages). */
class HookedProviderStages extends FirestoreProviderStageRepository {
  beforeClaim: ((stageId: string) => Promise<void>) | null = null;
  override async claimAttempt(
    ...args: Parameters<FirestoreProviderStageRepository['claimAttempt']>
  ): ReturnType<FirestoreProviderStageRepository['claimAttempt']> {
    if (this.beforeClaim) await this.beforeClaim(args[0]);
    return super.claimAttempt(...args);
  }
}

function harness() {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-10-05T10:00:00Z'));
  const repository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(
    repository,
    clock,
    provisionalWaitPolicy({ coffee: 60_000, palm: 60_000, soulmate: SOULMATE_NO_COMMERCIAL_WAIT_MS }),
  );
  const ledger = new GemLedger(store, clock, provisionalGemCostPolicy());
  const flow = new ReadingFlow(store, clock, operations, ledger);
  const objects = new HookedObjectStore();
  const stagedRepository = new FirestoreReadingStagedImageRepository(store);
  const stagedImages = new ReadingStagedImageService(
    stagedRepository,
    objects,
    operations,
    clock,
    testConfig({ READING_STAGING_BUCKET: 'test-bucket' }),
  );
  const results = new ReadingResultRepository(store);
  const providerStages = new HookedProviderStages(store);
  const soulmateInputs = new ReadingOperationInputService(
    new FirestoreReadingOperationInputRepository(store),
    operations,
    clock,
  );
  const portraits = new GcsSoulmatePortraitStore(objects, store);
  const entitlement = new InMemorySoulmateEntitlementGuard();
  const notified: string[] = [];

  const providerCalls: Array<{ identity: string; operation: string }> = [];
  const latches = new Map<string, Latch>();
  const ai = {
    async handle(
      request: { operation: string },
      _hint: unknown,
      context: { identity: string; parentKey: string },
    ): Promise<Record<string, unknown>> {
      providerCalls.push({ identity: context.identity, operation: request.operation });
      const latch = latches.get(`${context.identity}|${request.operation}`);
      if (latch) {
        latch.entered.resolve();
        await latch.release.promise;
      }
      if (request.operation === 'soulmate_draw') {
        return {
          imageBase64: fakePng('late-portrait').toString('base64'),
          mimeType: 'image/png',
          identity: { archetype: 'the-wanderer' },
        };
      }
      if (request.operation === 'soulmate_interpretation') {
        return {
          personality: 'p', dynamic: 'd', attraction: 'a',
          challenge: 'c', meeting: 'm', feeling: 'f',
        };
      }
      return { overall: 'late provider result', symbols: [], themes: [] };
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
    { async notifyCompleted(input) { notified.push(input.operationId); } },
    false,
    providerStages,
    undefined,
    soulmateInputs,
    portraits,
    entitlement,
  );

  const deletionStore = new DeletionFirestoreAdapter(store);
  const deletion = new FirestoreAccountDeletionRepository(
    deletionStore as unknown as Firestore,
    storageFake(objects, deletionStore) as unknown as Storage,
    'test-bucket',
  );

  function latch(identity: string, operation: string): Latch {
    const l = { entered: deferred(), release: deferred() };
    latches.set(`${identity}|${operation}`, l);
    return l;
  }

  async function createImageReading(owner: string, type: 'coffee' | 'palm', sourceRequestId: string) {
    const operation = await operations.create({ ownerUserId: owner, readingType: type, sourceRequestId });
    await flow.remember(operation);
    await stagedImages.stage({
      ownerUserId: owner,
      operationId: operation.operationId,
      mimeType: 'image/jpeg',
      imageBase64: fakeJpeg().toString('base64'),
      ...(type === 'palm' ? { handSide: 'right' } : {}),
    });
    clock.ms = Math.max(clock.ms, operation.readyAtMs);
    return operation;
  }

  async function createSoulmate(owner: string, sourceRequestId: string) {
    entitlement.grant(owner);
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
    clock.ms = Math.max(clock.ms, operation.readyAtMs);
    return operation;
  }

  /** Direct storage probe — never inferred from processor outcome. */
  function probe(operationId: string, owner: string) {
    const has = (path: string) => store.docs.has(path);
    return {
      operation: has(`readingOperations/${operationId}`),
      result: has(`readingOperationResults/${operationId}`),
      providerStage: has(`readingProviderStages/${operationId}`),
      portraitStage: has(`readingProviderStages/${operationId}:portrait`),
      interpretationStage: has(`readingProviderStages/${operationId}:interpretation`),
      portraitMeta: has(`readingSoulmatePortraits/${operationId}`),
      portraitObject: [...objects.objects.keys()]
        .some((key) => key.startsWith('soulmate-portraits/') && key.includes(operationId)),
      stagedObject: [...objects.objects.keys()]
        .some((key) => key.startsWith('reading-staging/') && key.includes(operationId)),
      ownerDocs: [...store.docs.entries()]
        .filter(([path, data]) => !path.startsWith('accountDeletionReceipts/') && data.ownerUserId === owner)
        .map(([path]) => path.split('/')[0])
        .sort(),
    };
  }

  return {
    store, clock, ledger, results, processor, objects, providerCalls, notified,
    providerStages, portraits,
    deletion, deletionStore, latch, createImageReading, createSoulmate, probe,
  };
}

async function settle<T>(promise: Promise<T>) {
  try {
    return { ok: true as const, value: await promise };
  } catch (error) {
    return { ok: false as const, error: error instanceof Error ? error.message : String(error) };
  }
}

const userA = identityKeyFromSubject('wave31-user-a');
const userB = identityKeyFromSubject('wave31-user-b');

// ==========================================================================
// SCENARIO A — Coffee / Palm late worker (RED pre-3.2, GREEN with barrier)
// ==========================================================================
describe.each(['coffee', 'palm'] as const)('SCENARIO A — %s late worker x account deletion', (type) => {
  it('no provider stage / reading result may be recreated after deletion completes', async () => {
    const h = harness();
    const op = await h.createImageReading(userA, type, `${type}-wave31-a`);
    const gate = h.latch(userA, `${type}_analysis`);

    const run = settle(h.processor.process(op.operationId));
    await gate.entered.promise;

    const beforeDelete = h.probe(op.operationId, userA);
    expect(beforeDelete.operation).toBe(true);
    expect(beforeDelete.providerStage).toBe(true); // in_flight claim checkpoint
    expect(beforeDelete.result).toBe(false);

    const receipt = await h.deletion.deleteForIdentity(userA);
    expect(receipt.status).toBe('accepted');
    const afterDelete = h.probe(op.operationId, userA);
    // Deletion itself must be complete before the worker resumes.
    expect(afterDelete.operation).toBe(false);
    expect(afterDelete.providerStage).toBe(false);
    expect(afterDelete.result).toBe(false);
    expect(afterDelete.stagedObject).toBe(false);
    expect(afterDelete.ownerDocs).toEqual([]);

    gate.release.resolve();
    const outcome = await run;
    const afterResume = h.probe(op.operationId, userA);

    // Informational: what a deletion retry does with resurrected data.
    const retryReceipt = await h.deletion.deleteForIdentity(userA);
    const afterDeletionRetry = h.probe(op.operationId, userA);
    console.info(`[WAVE3.1][${type}] ${JSON.stringify({
      beforeDelete, afterDelete, workerOutcome: outcome, afterResume,
      deletionRetrySameReceipt: retryReceipt.receiptId === receipt.receiptId,
      afterDeletionRetry,
      providerCalls: h.providerCalls.length,
      notified: h.notified.length,
    })}`);

    expect.soft(outcome, 'typed terminal outcome').toEqual({ ok: true, value: 'owner_deleted' });
    expect.soft(afterResume.providerStage, 'readingProviderStages/{op} recreated').toBe(false);
    expect.soft(afterResume.result, 'readingOperationResults/{op} recreated').toBe(false);
    expect.soft(afterResume.operation, 'readingOperations/{op} recreated').toBe(false);
    expect.soft(afterResume.ownerDocs, 'owner-scoped docs recreated').toEqual([]);
    expect.soft(h.notified, 'completion push for deleted identity').toEqual([]);
  });
});

// ==========================================================================
// SCENARIO B — Soulmate late worker (RED pre-3.2, GREEN with barrier)
// ==========================================================================
describe('SCENARIO B — Soulmate late worker x account deletion', () => {
  it('no portrait meta / portrait object / result / provider stage may be recreated after deletion completes', async () => {
    const h = harness();
    const op = await h.createSoulmate(userA, 'soulmate-wave31-a');
    const gate = h.latch(userA, 'soulmate_draw');

    const run = settle(h.processor.process(op.operationId));
    await gate.entered.promise;

    const beforeDelete = h.probe(op.operationId, userA);
    expect(beforeDelete.operation).toBe(true);
    expect(beforeDelete.portraitStage).toBe(true); // in_flight claim checkpoint
    expect(beforeDelete.portraitMeta).toBe(false);
    expect(beforeDelete.portraitObject).toBe(false);
    expect(beforeDelete.result).toBe(false);

    await h.deletion.deleteForIdentity(userA);
    const afterDelete = h.probe(op.operationId, userA);
    expect(afterDelete.operation).toBe(false);
    expect(afterDelete.portraitStage).toBe(false);
    expect(afterDelete.portraitMeta).toBe(false);
    expect(afterDelete.portraitObject).toBe(false);
    expect(afterDelete.result).toBe(false);
    expect(afterDelete.ownerDocs).toEqual([]);

    const callsBeforeResume = h.providerCalls.length;
    gate.release.resolve();
    const outcome = await run;
    const afterResume = h.probe(op.operationId, userA);
    const lateProviderCalls = h.providerCalls.slice(callsBeforeResume);
    console.info(`[WAVE3.1][soulmate] ${JSON.stringify({
      beforeDelete, afterDelete, workerOutcome: outcome, afterResume,
      lateProviderCalls, notified: h.notified.length,
    })}`);

    expect.soft(outcome, 'typed terminal outcome').toEqual({ ok: true, value: 'owner_deleted' });
    expect.soft(h.objects.puts.filter((p) => p.startsWith('soulmate-portraits/')), 'pre-upload barrier')
      .toEqual([]);
    expect.soft(afterResume.portraitMeta, 'readingSoulmatePortraits/{op} recreated').toBe(false);
    expect.soft(afterResume.portraitObject, 'soulmate-portraits/ GCS object recreated').toBe(false);
    expect.soft(afterResume.result, 'readingOperationResults/{op} recreated').toBe(false);
    expect.soft(afterResume.portraitStage, 'readingProviderStages/{op}:portrait recreated').toBe(false);
    expect.soft(afterResume.interpretationStage, 'readingProviderStages/{op}:interpretation recreated').toBe(false);
    expect.soft(afterResume.ownerDocs, 'owner-scoped docs recreated').toEqual([]);
    expect.soft(lateProviderCalls, 'paid provider call for deleted identity').toEqual([]);
    expect.soft(h.notified, 'completion push for deleted identity').toEqual([]);
  });
});

// ==========================================================================
// REQUIRED GUARDS (expected GREEN)
// ==========================================================================
describe('GUARD A — no deletion: normal worker completes', () => {
  it('coffee: provider called once, result persisted, ready', async () => {
    const h = harness();
    const op = await h.createImageReading(userA, 'coffee', 'coffee-wave31-guard-a');
    expect(await h.processor.process(op.operationId)).toBe('completed');
    expect(h.providerCalls).toHaveLength(1);
    const state = h.probe(op.operationId, userA);
    expect(state.result).toBe(true);
    expect(state.providerStage).toBe(true);
    expect(h.notified).toEqual([op.operationId]);
  });

  it('soulmate: portrait + interpretation, portrait meta/object and result persisted', async () => {
    const h = harness();
    const op = await h.createSoulmate(userA, 'soulmate-wave31-guard-a');
    expect(await h.processor.process(op.operationId)).toBe('completed');
    expect(h.providerCalls.map((c) => c.operation)).toEqual(['soulmate_draw', 'soulmate_interpretation']);
    const state = h.probe(op.operationId, userA);
    expect(state.result).toBe(true);
    expect(state.portraitMeta).toBe(true);
    expect(state.portraitObject).toBe(true);
  });
});

describe('GUARD B — deleting user A never blocks user B in-flight worker', () => {
  it('coffee: B completes and keeps its data while A is deleted mid-flight', async () => {
    const h = harness();
    const opA = await h.createImageReading(userA, 'coffee', 'coffee-wave31-guard-b-a');
    const opB = await h.createImageReading(userB, 'coffee', 'coffee-wave31-guard-b-b');
    const gateB = h.latch(userB, 'coffee_analysis');
    const runB = settle(h.processor.process(opB.operationId));
    await gateB.entered.promise;

    await h.deletion.deleteForIdentity(userA);
    expect(h.probe(opA.operationId, userA).ownerDocs).toEqual([]);

    gateB.release.resolve();
    expect(await runB).toEqual({ ok: true, value: 'completed' });
    const stateB = h.probe(opB.operationId, userB);
    expect(stateB.operation).toBe(true);
    expect(stateB.result).toBe(true);
    expect(stateB.providerStage).toBe(true);
    expect(h.notified).toEqual([opB.operationId]);
  });

  it('soulmate: B completes and keeps portrait/result while A is deleted mid-flight', async () => {
    const h = harness();
    const opA = await h.createSoulmate(userA, 'soulmate-wave31-guard-b-a');
    const opB = await h.createSoulmate(userB, 'soulmate-wave31-guard-b-b');
    const gateB = h.latch(userB, 'soulmate_draw');
    const runB = settle(h.processor.process(opB.operationId));
    await gateB.entered.promise;

    await h.deletion.deleteForIdentity(userA);
    expect(h.probe(opA.operationId, userA).ownerDocs).toEqual([]);

    gateB.release.resolve();
    expect(await runB).toEqual({ ok: true, value: 'completed' });
    const stateB = h.probe(opB.operationId, userB);
    expect(stateB.result).toBe(true);
    expect(stateB.portraitMeta).toBe(true);
    expect(stateB.portraitObject).toBe(true);
  });
});

describe('GUARD C — deletion completed before claim', () => {
  it.each(['coffee', 'palm'] as const)('%s: noop, no provider call, nothing written', async (type) => {
    const h = harness();
    const op = await h.createImageReading(userA, type, `${type}-wave31-guard-c`);
    await h.deletion.deleteForIdentity(userA);
    expect(await settle(h.processor.process(op.operationId))).toEqual({ ok: true, value: 'noop' });
    expect(h.providerCalls).toHaveLength(0);
    const state = h.probe(op.operationId, userA);
    expect(state.result).toBe(false);
    expect(state.providerStage).toBe(false);
    expect(state.ownerDocs).toEqual([]);
  });

  it('soulmate: noop, no provider call, no portrait written', async () => {
    const h = harness();
    const op = await h.createSoulmate(userA, 'soulmate-wave31-guard-c');
    await h.deletion.deleteForIdentity(userA);
    expect(await settle(h.processor.process(op.operationId))).toEqual({ ok: true, value: 'noop' });
    expect(h.providerCalls).toHaveLength(0);
    const state = h.probe(op.operationId, userA);
    expect(state.portraitMeta).toBe(false);
    expect(state.portraitObject).toBe(false);
    expect(state.result).toBe(false);
    expect(state.ownerDocs).toEqual([]);
  });
});

describe('GUARD D — deletion idempotency', () => {
  it('second call returns the same receipt and performs no further mutation', async () => {
    const h = harness();
    await h.createImageReading(userA, 'coffee', 'coffee-wave31-guard-d');
    const first = await h.deletion.deleteForIdentity(userA);
    const eventsAfterFirst = [...h.deletionStore.events];
    const docsAfterFirst = JSON.stringify([...h.store.docs.entries()]);
    const second = await h.deletion.deleteForIdentity(userA);
    expect(second.receiptId).toBe(first.receiptId);
    expect(second).toMatchObject({
      receiptId: first.receiptId,
      status: 'accepted',
      completedAt: first.completedAt,
      deletedDocuments: first.deletedDocuments,
    });
    expect(h.deletionStore.events).toEqual(eventsAfterFirst);
    expect(JSON.stringify([...h.store.docs.entries()])).toBe(docsAfterFirst);
  });
});

describe('GUARD E — gem / refund side effects in the deletion race', () => {
  it('accelerated coffee: no extra debit, no refund, no resurrected balance — including a redelivery', async () => {
    const h = harness();
    const op = await h.createImageReading(userA, 'coffee', 'coffee-wave31-guard-e');
    h.clock.ms = op.readyAtMs - 30_000; // not yet free-eligible: acceleration is what makes it run
    await h.ledger.credit({ ownerUserId: userA, amount: 40, idempotencyKey: 'wave31-seed-e' });
    await h.ledger.accelerate({ ownerUserId: userA, operationId: op.operationId, idempotencyKey: 'wave31-accel-e' });
    const spendsBefore = [...h.store.docs.values()].filter((d) => d.type === 'spend');
    expect(spendsBefore).toHaveLength(1);

    const gate = h.latch(userA, 'coffee_analysis');
    const run = settle(h.processor.process(op.operationId));
    await gate.entered.promise;
    await h.deletion.deleteForIdentity(userA);
    gate.release.resolve();
    await run;
    // Cloud Tasks redelivery after the late failure.
    const redelivery = await settle(h.processor.process(op.operationId));
    expect(redelivery).toEqual({ ok: true, value: 'noop' });

    const gemDocs = [...h.store.docs.keys()].filter((path) => path.startsWith('gem'));
    expect(gemDocs).toEqual([]);
    expect([...h.store.docs.values()].filter((d) => d.type === 'spend')).toHaveLength(0);
    expect([...h.store.docs.values()].filter((d) => d.type === 'refund')).toHaveLength(0);
    expect(await h.ledger.balanceOf(userA)).toBe(0);
    expect(h.providerCalls).toHaveLength(1);
  });
});

// ==========================================================================
// PHASE 2 — barrier timing (WAVE 3.2 contract)
// ==========================================================================
describe('BARRIER — deletion receipt/barrier timing', () => {
  it('barrier is written FIRST (before any destructive op), kept through the sweep, finalized LAST', async () => {
    const h = harness();
    await h.createSoulmate(userA, 'soulmate-wave31-receipt');
    await h.createImageReading(userA, 'coffee', 'coffee-wave31-receipt');
    // Seed a portrait so the object-deletion step is exercised too.
    expect(await h.processor.process((await h.createSoulmate(userA, 'soulmate-wave31-receipt-2')).operationId))
      .toBe('completed');

    const receipt = await h.deletion.deleteForIdentity(userA);
    const events = h.deletionStore.events;
    console.info(`[WAVE3.2][barrier-timing] ${JSON.stringify(events)}`);

    expect(h.deletionStore.receiptExistedAtFirstDestructiveOp).toBe(true);
    expect(events[0]).toBe('set:accountDeletionReceipts');
    expect(events.at(-1)).toBe('set:accountDeletionReceipts');
    expect(events.filter((e) => e === 'set:accountDeletionReceipts')).toHaveLength(2);
    expect(events.slice(1, -1).every((e) => e.startsWith('object:') || e.startsWith('delete:'))).toBe(true);
    const stored = h.store.docs.get(`accountDeletionReceipts/${receipt.receiptId}`);
    expect(stored?.status).toBe('accepted');
    expect(stored?.expiresAt).toBeDefined();
  });

  it('a crashed partial deletion leaves a deleting barrier; a retry resumes and finalizes it', async () => {
    const h = harness();
    const op = await h.createImageReading(userA, 'coffee', 'coffee-wave32-resume');
    // Simulate a crash right after the barrier commit: barrier present, nothing swept.
    const barrierPath = `accountDeletionReceipts/${accountDeletionReceiptId(userA)}`;
    h.store.docs.set(barrierPath, {
      receiptId: accountDeletionReceiptId(userA), status: 'deleting', deletionStartedAt: 'x',
    });
    // While deleting, the worker is already refused.
    expect(await h.processor.process(op.operationId)).toBe('owner_deleted');
    expect(h.providerCalls).toHaveLength(0);

    const receipt = await h.deletion.deleteForIdentity(userA);
    expect(receipt).toMatchObject({ receiptId: accountDeletionReceiptId(userA), status: 'accepted' });
    expect(h.store.docs.get(barrierPath)?.status).toBe('accepted');
    expect(h.probe(op.operationId, userA).ownerDocs).toEqual([]);
    expect(h.probe(op.operationId, userA).stagedObject).toBe(false);
  });
});

// ==========================================================================
// WAVE 3.2 — write-path barriers (direct)
// ==========================================================================
describe('WRITE BARRIERS — deleting/deleted owner is refused at every creating write', () => {
  function seedBarrier(h: ReturnType<typeof harness>, owner: string, status: 'deleting' | 'accepted') {
    h.store.docs.set(`accountDeletionReceipts/${accountDeletionReceiptId(owner)}`, {
      receiptId: accountDeletionReceiptId(owner), status,
    });
  }

  it.each(['deleting', 'accepted'] as const)('%s: provider stage claim/markInFlight/markCompleted write nothing', async (status) => {
    const h = harness();
    seedBarrier(h, userA, status);
    await expect(h.providerStages.claimAttempt('op-x', userA)).rejects.toThrow('account_deleted');
    await expect(h.providerStages.markInFlight('op-x', userA)).rejects.toThrow('account_deleted');
    await expect(h.providerStages.markCompleted('op-x', userA, { overall: 'x' })).rejects.toThrow('account_deleted');
    expect(h.store.docs.has('readingProviderStages/op-x')).toBe(false);
    // Cross-owner: B is unaffected by A's barrier.
    expect((await h.providerStages.claimAttempt('op-y', userB)).initiate).toBe(true);
  });

  it.each(['deleting', 'accepted'] as const)('%s: reading result persistOnce writes nothing', async (status) => {
    const h = harness();
    seedBarrier(h, userA, status);
    const record = (owner: string, operationId: string) => ({
      schemaVersion: 1 as const, operationId, ownerUserId: owner, readingType: 'coffee' as const,
      resultId: `coffee_${operationId}`, data: { overall: 'x' }, persistedAtMs: 1, notificationSentAtMs: null,
    });
    await expect(h.results.persistOnce(record(userA, 'op-a'))).rejects.toThrow('account_deleted');
    expect(h.store.docs.has('readingOperationResults/op-a')).toBe(false);
    // Normal owner: first-writer idempotency unchanged.
    const first = await h.results.persistOnce(record(userB, 'op-b'));
    const replay = await h.results.persistOnce({ ...record(userB, 'op-b'), data: { overall: 'second' } });
    expect(replay.data).toEqual(first.data);
  });

  it('portrait PRE-UPLOAD barrier: no object upload, no metadata', async () => {
    const h = harness();
    seedBarrier(h, userA, 'deleting');
    await expect(h.portraits.put({
      operationId: 'op-p', ownerUserId: userA, bytes: fakePng('x'), contentType: 'image/png',
      identity: { archetype: 'x' } as never,
    })).rejects.toThrow('account_deleted');
    expect(h.objects.puts).toEqual([]);
    expect(h.store.docs.has('readingSoulmatePortraits/op-p')).toBe(false);
  });

  it('portrait POST-UPLOAD race: deletion between upload and meta commit -> no meta, uploaded object removed', async () => {
    const h = harness();
    const op = await h.createSoulmate(userA, 'soulmate-wave32-post-upload');
    let objectSurvivedSweep = false;
    h.objects.afterPut = async (path) => {
      if (path.startsWith('soulmate-portraits/')) {
        h.objects.afterPut = null;
        await h.deletion.deleteForIdentity(userA);
        // The sweep could not see this object (no metadata yet).
        objectSurvivedSweep = h.objects.objects.has(path);
      }
    };
    expect(await h.processor.process(op.operationId)).toBe('owner_deleted');
    expect(objectSurvivedSweep).toBe(true);
    const state = h.probe(op.operationId, userA);
    expect(h.objects.puts.filter((p) => p.startsWith('soulmate-portraits/'))).toHaveLength(1);
    expect(state.portraitObject).toBe(false);
    expect(state.portraitMeta).toBe(false);
    expect(state.result).toBe(false);
    expect(state.ownerDocs).toEqual([]);
    expect(h.providerCalls.map((c) => c.operation)).toEqual(['soulmate_draw']);
  });
});

// ==========================================================================
// GUARD F — no second paid Soulmate provider call after deletion
// ==========================================================================
describe('GUARD F — Soulmate second provider call', () => {
  it('deletion after the portrait stage, before interpretation: interpretation is never called', async () => {
    const h = harness();
    const op = await h.createSoulmate(userA, 'soulmate-wave32-guard-f');
    let portraitDurableBeforeDelete = false;
    h.providerStages.beforeClaim = async (stageId) => {
      if (stageId.endsWith(':interpretation')) {
        h.providerStages.beforeClaim = null;
        portraitDurableBeforeDelete = h.probe(op.operationId, userA).portraitObject;
        await h.deletion.deleteForIdentity(userA);
      }
    };
    expect(await h.processor.process(op.operationId)).toBe('owner_deleted');
    expect(portraitDurableBeforeDelete).toBe(true);
    expect(h.providerCalls.map((c) => c.operation)).toEqual(['soulmate_draw']);
    const state = h.probe(op.operationId, userA);
    expect(state.interpretationStage).toBe(false);
    expect(state.portraitStage).toBe(false);
    expect(state.portraitMeta).toBe(false);
    expect(state.portraitObject).toBe(false);
    expect(state.result).toBe(false);
    expect(state.ownerDocs).toEqual([]);
    expect(h.notified).toEqual([]);
  });
});
