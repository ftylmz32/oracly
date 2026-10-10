/**
 * Slice 4D — legacy single-photo (unslotted) Coffee terminal delivery.
 *
 * `ReadingPipeline.coffee()` returns the same structured
 * `{ status: 'insufficient_semantic_signal', reason }` outcome as V2. The
 * durable worker's legacy branch (no V2 slots, no V3 contract) must settle
 * it — fresh or replayed from the provider-stage checkpoint — as a typed
 * terminal failure, never `persistOnce()` / `flow.complete()` / a result id
 * / a push. Only the DURABLE worker path is affected: the historical
 * two-phase observe/write client calls carry `readingPhase` and are served
 * by the public AI route, which never persists anything.
 * REAL worker (`ReadingProcessor.process`), real repositories, zero real
 * provider calls.
 */
import { beforeEach, describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { AiProxyService } from '../src/ai/service.js';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../src/reading/operation-staged-image-service.js';
import { FirestoreProviderStageRepository } from '../src/reading/provider-stage-repository.js';
import { ReadingFlow } from '../src/reading/reading-flow.js';
import { ReadingProcessor, type ReadingCompletionNotifier } from '../src/reading/reading-processor.js';
import { ReadingResultRepository } from '../src/reading/reading-result-repository.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import type { ServerClock } from '../src/reading/clock.js';
import type { CoffeeObservation } from '../src/ai/reading/types.js';
import { fakeJpeg, jsonResponse, testConfig } from './helpers.js';

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date {
    return new Date(this.ms);
  }
}

class RecordingNotifier implements ReadingCompletionNotifier {
  calls: string[] = [];
  async notifyCompleted(input: { operationId: string }): Promise<void> {
    this.calls.push(input.operationId);
  }
}

const NO_FACETS = { status: 'insufficient_semantic_signal', reason: 'no_safe_semantic_facets' } as const;
const NO_CAPACITY = { status: 'insufficient_semantic_signal', reason: 'insufficient_semantic_capacity' } as const;

/** A legitimate legacy public Coffee reading (toPublicCoffee shape). */
const VALID = {
  visualObservation: 'Fincanın kenarında yoğunlaşan izler sakin bir hareketi taşıyor.',
  overall:
    'Yakın çevrende kurulan açık bir söz alışverişi, sana en yakın alanın havasını daha anlaşılır kılabilir.',
  love: '',
  career: '',
  money: '',
  nearFuture: '',
  takeaway: 'Açıkça söylenenler, anlaşılma payını büyütebilir.',
  symbols: [],
};

type HandleScript = () => Promise<Record<string, unknown>>;

function worker(script: HandleScript | null) {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-10-11T00:00:00.000Z'));
  const policy = provisionalWaitPolicy({ coffee: 1000, palm: 1000, soulmate: 1000 });
  const operationRepository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(operationRepository, clock, policy);
  const stagedRepository = new FirestoreReadingStagedImageRepository(store);
  const objects = new MemoryStagedObjectStore();
  const config = testConfig();
  const stagedImages = new ReadingStagedImageService(stagedRepository, objects, operations, clock, config);
  const ledger = new GemLedger(store, clock, provisionalGemCostPolicy({ coffee: 10, palm: 15, soulmate: 20 }));
  const flow = new ReadingFlow(store, clock, operations, ledger);
  const results = new ReadingResultRepository(store);
  const providerStages = new FirestoreProviderStageRepository(store);
  const notifier = new RecordingNotifier();
  let handleCalls = 0;
  const seenPayloads: Array<Record<string, unknown>> = [];
  const ai = {
    handle: async (request: { payload: Record<string, unknown> }) => {
      handleCalls += 1;
      seenPayloads.push(request.payload);
      if (!script) throw new Error('unexpected provider call');
      return script();
    },
  };
  const processor = new ReadingProcessor(
    operationRepository, flow, stagedRepository, stagedImages, results,
    ai as never, clock, notifier, false, providerStages,
  );
  const owner = identityKeyFromSubject('slice4d-owner');

  /** An unslotted, single-image legacy Coffee operation (optionally trusted intention). */
  async function legacyOp(tag: string, { intention = false } = {}) {
    const op = await operations.create({
      ownerUserId: owner,
      readingType: 'coffee',
      sourceRequestId: `slice4d-${tag}`,
      ...(intention
        ? { coffeeInputContract: 'trusted_intention_v1' as const, coffeeIntention: 'İşim ve kariyerim hakkında' }
        : {}),
    });
    await flow.remember(op);
    await stagedImages.stage({
      ownerUserId: owner,
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: fakeJpeg(41_000).toString('base64'),
    });
    clock.ms = Math.max(clock.ms, op.readyAtMs);
    return op;
  }

  const resultDocs = () => [...store.docs.keys()].filter((k) => k.includes('readingOperationResults/')).length;
  const refunds = () => [...store.docs.values()].filter((d) => (d as { type?: string }).type === 'refund').length;
  const record = async (id: string) => (await operationRepository.getById(id))!;
  const staged = (id: string) => stagedRepository.get(id, owner);
  const v2Slots = (id: string) => stagedRepository.listSlots(id, owner);
  return {
    store, clock, config, operations, operationRepository, stagedRepository, stagedImages, objects,
    ledger, flow, results, providerStages, notifier, processor, owner,
    legacyOp, resultDocs, refunds, record, staged, v2Slots,
    handleCalls: () => handleCalls, seenPayloads,
  };
}

type Harness = ReturnType<typeof worker>;

async function expectTerminal(h: Harness, operationId: string, failureCode: 'invalid' | 'unavailable') {
  expect(await h.record(operationId)).toMatchObject({ status: 'failed', failureCode, resultId: null });
  expect(h.resultDocs()).toBe(0);
  expect(await h.results.get(operationId)).toBeNull();
  expect(h.notifier.calls).toEqual([]);
  await expect(
    h.flow.complete({ ownerUserId: h.owner, operationId, resultId: `coffee_${operationId}` }),
  ).rejects.toBeTruthy();
}

async function expectUnslottedCleaned(h: Harness, operationId: string) {
  expect(await h.staged(operationId)).toBeNull();
  expect(h.objects.objects.size).toBe(0);
}

beforeEach(() => readingStageStore.clear());

describe('Slice 4D — legacy unslotted Coffee insufficient outcome is terminal', () => {
  for (const [label, outcome] of [
    ['no_safe_semantic_facets', NO_FACETS],
    ['insufficient_semantic_capacity', NO_CAPACITY],
  ] as const) {
    for (const intention of [false, true]) {
      it(`${label} (${intention ? 'trusted intention' : 'no intention'}): failed(invalid), nothing persisted, no push, image cleaned`, async () => {
        const h = worker(async () => ({ ...outcome }));
        const op = await h.legacyOp(`${label}-${intention}`, { intention });
        expect(await h.v2Slots(op.operationId)).toEqual([]); // genuinely legacy
        expect(await h.staged(op.operationId)).not.toBeNull();
        expect(await h.processor.process(op.operationId)).toBe('failed');
        expect(h.handleCalls()).toBe(1);
        // The durable legacy call shape: no readingPhase (not the two-phase client path).
        expect(h.seenPayloads[0].readingPhase).toBeUndefined();
        await expectTerminal(h, op.operationId, 'invalid');
        await expectUnslottedCleaned(h, op.operationId);
        expect(await h.processor.process(op.operationId)).toBe('noop');
        expect(h.handleCalls()).toBe(1);
      });
    }
  }

  it('malformed / unexpected non-reading output fails closed (unavailable)', async () => {
    const shapes: Array<Record<string, unknown>> = [
      { status: 'insufficient_semantic_signal', reason: 'other' },
      { status: 'insufficient_semantic_signal' },
      { ...NO_FACETS, overall: 'smuggled prose' },
      { status: 'reading', narrative: {} },
      { ...VALID, overall: 7 },
      { ...VALID, overall: '  ' },
      { visualObservation: 'only' },
    ];
    for (const [i, shape] of shapes.entries()) {
      const h = worker(async () => ({ ...shape }));
      const op = await h.legacyOp(`malformed-${i}`);
      expect(await h.processor.process(op.operationId)).toBe('failed');
      await expectTerminal(h, op.operationId, 'unavailable');
      await expectUnslottedCleaned(h, op.operationId);
    }
  });

  it('a recorded provider-stage insufficient output replays as terminal (no provider call)', async () => {
    const h = worker(null);
    const op = await h.legacyOp('replay');
    await h.providerStages.claimAttempt(op.operationId, h.owner);
    await h.providerStages.markCompleted(op.operationId, h.owner, { ...NO_FACETS });
    expect(await h.processor.process(op.operationId)).toBe('failed');
    expect(h.handleCalls()).toBe(0);
    await expectTerminal(h, op.operationId, 'invalid');
    await expectUnslottedCleaned(h, op.operationId);
  });

  it('a transient terminal-write failure keeps the input, never succeeds, never regenerates', async () => {
    const h = worker(async () => ({ ...NO_CAPACITY }));
    const op = await h.legacyOp('transient-fail-write');
    const realFailFinal = h.flow.failFinal.bind(h.flow);
    let calls = 0;
    h.flow.failFinal = async (input) => {
      calls += 1;
      if (calls === 1) throw new Error('firestore hiccup');
      return realFailFinal(input);
    };
    await expect(h.processor.process(op.operationId)).rejects.toMatchObject({ retryable: true });
    const mid = await h.record(op.operationId);
    expect(mid.status).not.toBe('ready');
    expect(mid.resultId).toBeNull();
    expect(h.resultDocs()).toBe(0);
    expect(h.notifier.calls).toEqual([]);
    expect(await h.staged(op.operationId)).not.toBeNull(); // kept for the retry

    expect(await h.processor.process(op.operationId)).toBe('failed');
    expect(h.handleCalls()).toBe(1);
    await expectTerminal(h, op.operationId, 'invalid');
    await expectUnslottedCleaned(h, op.operationId);
  });

  it('accelerated legacy op: authoritative refund exactly once, even on retries', async () => {
    const h = worker(async () => ({ ...NO_FACETS }));
    await h.ledger.credit({ ownerUserId: h.owner, amount: 40, idempotencyKey: 'seed-credit-slice4d' });
    const op = await h.legacyOp('accelerated');
    h.clock.ms = op.createdAtMs;
    await h.ledger.accelerate({ ownerUserId: h.owner, operationId: op.operationId, idempotencyKey: 'accelerate-slice4d' });
    expect(await h.ledger.balanceOf(h.owner)).toBe(30);
    expect(await h.processor.process(op.operationId)).toBe('failed');
    expect(h.refunds()).toBe(1);
    expect(await h.ledger.balanceOf(h.owner)).toBe(40);
    expect(await h.processor.process(op.operationId)).toBe('noop');
    await h.flow.failFinal({ ownerUserId: h.owner, operationId: op.operationId, failureCode: 'invalid' });
    expect(h.refunds()).toBe(1);
    expect(await h.ledger.balanceOf(h.owner)).toBe(40);
  });

  it('no Gem debit → no fictitious refund', async () => {
    const h = worker(async () => ({ ...NO_CAPACITY }));
    await h.ledger.credit({ ownerUserId: h.owner, amount: 25, idempotencyKey: 'seed-credit-slice4d-nd' });
    const op = await h.legacyOp('no-debit');
    expect(await h.processor.process(op.operationId)).toBe('failed');
    expect(h.refunds()).toBe(0);
    expect(await h.ledger.balanceOf(h.owner)).toBe(25);
    expect(h.operations).toBeDefined();
  });
});

describe('Slice 4D — legacy unchanged behavior', () => {
  it('a valid legacy reading still completes, persists once, notifies once, cleans the image', async () => {
    for (const intention of [false, true]) {
      const h = worker(async () => ({ ...VALID }));
      const op = await h.legacyOp(`valid-${intention}`, { intention });
      expect(await h.processor.process(op.operationId)).toBe('completed');
      expect(await h.record(op.operationId)).toMatchObject({ status: 'ready', resultId: `coffee_${op.operationId}` });
      expect(h.resultDocs()).toBe(1);
      expect(h.notifier.calls).toEqual([op.operationId]);
      await expectUnslottedCleaned(h, op.operationId);
    }
  });

  it('a transient provider error keeps the existing retryable semantics', async () => {
    const h = worker(async () => {
      throw new Error('provider 503');
    });
    const op = await h.legacyOp('provider-transient');
    await expect(h.processor.process(op.operationId)).rejects.toMatchObject({ retryable: true });
    const stored = await h.record(op.operationId);
    expect(stored.status).not.toBe('failed');
    expect(stored.status).not.toBe('ready');
    expect(h.resultDocs()).toBe(0);
    expect(await h.staged(op.operationId)).not.toBeNull();
  });

  it('Palm is never classified as Coffee (its own reading shape still completes)', async () => {
    const h = worker(async () => ({
      visualObservation: 'v', overall: '', lifeLine: '', headLine: '', heartLine: '', fateLine: '',
      takeaway: '', symbols: [], themes: [],
    }));
    const op = await h.operations.create({ ownerUserId: h.owner, readingType: 'palm', sourceRequestId: 'slice4d-palm' });
    await h.flow.remember(op);
    await h.stagedImages.stage({
      ownerUserId: h.owner, operationId: op.operationId, mimeType: 'image/jpeg',
      imageBase64: fakeJpeg(41_000).toString('base64'), handSide: 'right',
    });
    h.clock.ms = op.readyAtMs;
    expect(await h.processor.process(op.operationId)).toBe('completed');
  });
});

describe('Slice 4D — real chain: fake provider → real legacy pipeline → real worker', () => {
  const noMeaningObservation = (): CoffeeObservation => ({
    usable: true,
    reason: '',
    checks: {
      cupInteriorVisible: true,
      residueVisible: true,
      usefulRegionsVisible: true,
      milkFoamObstruction: false,
      adequateFocusLight: true,
    },
    evidence: [
      { id: 'e1', region: 'base', description: 'odd silhouette', resemblance: 'purple dragon', confidence: 'high', visibility: 'clear' },
      { id: 'e2', region: 'rim', description: 'odd outline', resemblance: 'green teapot', confidence: 'high', visibility: 'clear' },
      { id: 'e3', region: 'middle_wall', description: 'odd smear', resemblance: 'silver comet', confidence: 'high', visibility: 'clear' },
    ],
  } as CoffeeObservation);

  it('the real legacy pipeline insufficient outcome reaches the seam and ends terminal', async () => {
    const seen: string[] = [];
    const fetchImpl = async (_url: unknown, init?: RequestInit) => {
      const body = JSON.parse(String(init?.body ?? '{}')) as { response_format?: { json_schema?: { name?: string } } };
      const name = body.response_format?.json_schema?.name ?? 'unknown';
      seen.push(name);
      if (name === 'coffee_observation') {
        return jsonResponse({ choices: [{ message: { content: JSON.stringify(noMeaningObservation()) } }] });
      }
      throw new Error(`unexpected provider call: ${name}`);
    };
    const h = worker(null);
    const real = new AiProxyService(h.config, fetchImpl as typeof fetch, h.stagedImages);
    const processor = new ReadingProcessor(
      h.operationRepository, h.flow, h.stagedRepository, h.stagedImages, h.results,
      { handle: (...args: Parameters<AiProxyService['handle']>) => real.handle(...args) },
      h.clock, h.notifier, false, h.providerStages,
    );
    const op = await h.legacyOp('real-chain');
    expect(await processor.process(op.operationId)).toBe('failed');
    expect(seen).toEqual(['coffee_observation']); // observer only, no writer
    await expectTerminal(h, op.operationId, 'invalid');
    await expectUnslottedCleaned(h, op.operationId);
  });
});
