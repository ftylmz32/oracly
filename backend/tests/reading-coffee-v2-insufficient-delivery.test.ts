/**
 * Slice 4C — Coffee V2 insufficient-result terminal delivery.
 *
 * `ReadingPipeline.coffeeV2()` can return a structured
 * `{ status: 'insufficient_semantic_signal', reason }` instead of a reading.
 * At the durable worker seam (`executeClaimedReading`) that object must be
 * a typed terminal failure — never `persistOnce()` / `flow.complete()` /
 * a result id / a completion push — on the fresh path AND when replayed
 * from a recorded provider-stage checkpoint. Exercises the REAL worker
 * (`ReadingProcessor.process`) over real flow / ledger / staging / result /
 * provider-stage repositories. Zero real provider calls.
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
import type { CoffeeV2Observation } from '../src/ai/reading/types.js';
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

/** A legitimate public Coffee reading (toPublicCoffee shape). */
const VALID = {
  visualObservation: 'Çevrendeki tanıdık hava, gelişmenin sessiz arka planını oluşturuyor.',
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
  const ai = {
    handle: async () => {
      handleCalls += 1;
      if (!script) throw new Error('unexpected provider call');
      return script();
    },
  };
  const processor = new ReadingProcessor(
    operationRepository, flow, stagedRepository, stagedImages, results, ai, clock, notifier, false, providerStages,
  );
  const owner = identityKeyFromSubject('slice4c-owner');

  async function v2Op(tag: string, { stage = true } = {}) {
    const op = await operations.create({
      ownerUserId: owner,
      readingType: 'coffee',
      sourceRequestId: `slice4c-${tag}`,
      coffeeInputContract: 'trusted_intention_v1',
      coffeeIntention: 'Aşk ve ilişkilerim hakkında',
    });
    await flow.remember(op);
    if (stage) {
      for (const [i, slot] of ['cup_primary', 'cup_secondary', 'saucer'].entries()) {
        await stagedImages.stage({
          ownerUserId: owner,
          operationId: op.operationId,
          mimeType: 'image/jpeg',
          imageBase64: fakeJpeg(30_000 + i * 97).toString('base64'),
          slot,
        });
      }
    }
    clock.ms = Math.max(clock.ms, op.readyAtMs);
    return op;
  }

  const resultDocs = () => [...store.docs.keys()].filter((k) => k.includes('readingOperationResults/')).length;
  const refunds = () => [...store.docs.values()].filter((d) => (d as { type?: string }).type === 'refund').length;
  const record = async (id: string) => (await operationRepository.getById(id))!;
  const slots = (id: string) => stagedRepository.listSlots(id, owner);
  return {
    store, clock, config, operations, operationRepository, stagedRepository, stagedImages, objects,
    ledger, flow, results, providerStages, notifier, processor, owner,
    v2Op, resultDocs, refunds, record, slots, handleCalls: () => handleCalls,
  };
}

type Harness = ReturnType<typeof worker>;

async function expectTerminal(h: Harness, operationId: string, failureCode: 'invalid' | 'unavailable') {
  const stored = await h.record(operationId);
  expect(stored).toMatchObject({ status: 'failed', failureCode, resultId: null });
  expect(h.resultDocs()).toBe(0);
  expect(await h.results.get(operationId)).toBeNull();
  expect(h.notifier.calls).toEqual([]);
  // The failed operation can never be completed afterwards.
  await expect(
    h.flow.complete({ ownerUserId: h.owner, operationId, resultId: `coffee_${operationId}` }),
  ).rejects.toBeTruthy();
}

beforeEach(() => readingStageStore.clear?.());

describe('Slice 4C — V2 insufficient outcome is terminal, never a reading', () => {
  for (const [label, outcome] of [
    ['no_safe_semantic_facets', NO_FACETS],
    ['insufficient_semantic_capacity', NO_CAPACITY],
  ] as const) {
    it(`1-6 ${label}: failed(invalid), nothing persisted, no push, staged V2 photos cleaned`, async () => {
      const h = worker(async () => ({ ...outcome }));
      const op = await h.v2Op(label);
      expect(await h.slots(op.operationId)).toHaveLength(3);
      expect(await h.processor.process(op.operationId)).toBe('failed');
      expect(h.handleCalls()).toBe(1);
      await expectTerminal(h, op.operationId, 'invalid');
      expect(await h.slots(op.operationId)).toEqual([]);
      expect(h.objects.objects.size).toBe(0);
      // Redelivery: nothing left to do, no second provider call.
      expect(await h.processor.process(op.operationId)).toBe('noop');
      expect(h.handleCalls()).toBe(1);
    });
  }

  it('8 a recorded provider-stage insufficient output is replayed as terminal (no provider call)', async () => {
    const h = worker(null);
    const op = await h.v2Op('replay');
    await h.providerStages.claimAttempt(op.operationId, h.owner);
    await h.providerStages.markCompleted(op.operationId, h.owner, { ...NO_CAPACITY });
    expect(await h.processor.process(op.operationId)).toBe('failed');
    expect(h.handleCalls()).toBe(0);
    await expectTerminal(h, op.operationId, 'invalid');
    expect(await h.slots(op.operationId)).toEqual([]);
  });

  it('7 a transient terminal-write failure never becomes a success and never regenerates', async () => {
    const h = worker(async () => ({ ...NO_FACETS }));
    const op = await h.v2Op('transient-fail-write');
    const realFailFinal = h.flow.failFinal.bind(h.flow);
    let failFinalCalls = 0;
    h.flow.failFinal = async (input) => {
      failFinalCalls += 1;
      if (failFinalCalls === 1) throw new Error('firestore hiccup');
      return realFailFinal(input);
    };
    await expect(h.processor.process(op.operationId)).rejects.toMatchObject({ retryable: true });
    const mid = await h.record(op.operationId);
    expect(mid.status).not.toBe('ready');
    expect(mid.resultId).toBeNull();
    expect(h.resultDocs()).toBe(0);
    expect(h.notifier.calls).toEqual([]);
    // Staged photos are kept until the terminal outcome is durable.
    expect(await h.slots(op.operationId)).toHaveLength(3);

    expect(await h.processor.process(op.operationId)).toBe('failed');
    expect(h.handleCalls()).toBe(1); // replayed from the checkpoint
    await expectTerminal(h, op.operationId, 'invalid');
    expect(await h.slots(op.operationId)).toEqual([]);
  });

  it('9/10 accelerated V2: authoritative refund exactly once, even on retries', async () => {
    const h = worker(async () => ({ ...NO_FACETS }));
    await h.ledger.credit({ ownerUserId: h.owner, amount: 40, idempotencyKey: 'seed-credit-slice4c' });
    const op = await h.v2Op('accelerated');
    h.clock.ms = op.createdAtMs; // still waiting → acceleration is payable
    await h.ledger.accelerate({ ownerUserId: h.owner, operationId: op.operationId, idempotencyKey: 'accelerate-slice4c' });
    expect(await h.ledger.balanceOf(h.owner)).toBe(30);
    expect(await h.processor.process(op.operationId)).toBe('failed');
    expect(h.refunds()).toBe(1);
    expect(await h.ledger.balanceOf(h.owner)).toBe(40);
    // Retried / concurrent terminal handling cannot refund twice.
    expect(await h.processor.process(op.operationId)).toBe('noop');
    await h.flow.failFinal({ ownerUserId: h.owner, operationId: op.operationId, failureCode: 'invalid' });
    expect(h.refunds()).toBe(1);
    expect(await h.ledger.balanceOf(h.owner)).toBe(40);
    await expectTerminal(h, op.operationId, 'invalid');
  });

  it('11 no Gem debit → no fictitious refund', async () => {
    const h = worker(async () => ({ ...NO_CAPACITY }));
    await h.ledger.credit({ ownerUserId: h.owner, amount: 25, idempotencyKey: 'seed-credit-slice4c-11' });
    const op = await h.v2Op('no-debit');
    expect(await h.processor.process(op.operationId)).toBe('failed');
    expect(h.refunds()).toBe(0);
    expect(await h.ledger.balanceOf(h.owner)).toBe(25);
  });

  it('malformed / unexpected shapes fail closed — never a fabricated reading', async () => {
    const shapes: Array<Record<string, unknown>> = [
      { status: 'insufficient_semantic_signal', reason: 'something_else' },
      { status: 'insufficient_semantic_signal' },
      { ...NO_FACETS, overall: 'smuggled prose' },
      { status: 'reading', narrative: {} },
      { ...VALID, overall: 7 },
      { ...VALID, overall: '   ' },
      { visualObservation: 'x' },
    ];
    for (const [i, shape] of shapes.entries()) {
      const h = worker(async () => ({ ...shape }));
      const op = await h.v2Op(`malformed-${i}`);
      expect(await h.processor.process(op.operationId)).toBe('failed');
      await expectTerminal(h, op.operationId, 'unavailable');
    }
  });
});

describe('Slice 4C — unchanged behavior', () => {
  it('12 a valid V2 reading still completes, persists once and notifies once', async () => {
    const h = worker(async () => ({ ...VALID }));
    const op = await h.v2Op('valid');
    expect(await h.processor.process(op.operationId)).toBe('completed');
    expect(await h.record(op.operationId)).toMatchObject({ status: 'ready', resultId: `coffee_${op.operationId}` });
    expect(h.resultDocs()).toBe(1);
    expect(h.notifier.calls).toEqual([op.operationId]);
    expect(await h.slots(op.operationId)).toEqual([]);
  });

  it('13 a transient provider error keeps the existing retryable semantics', async () => {
    const h = worker(async () => {
      throw new Error('provider 503');
    });
    const op = await h.v2Op('provider-transient');
    await expect(h.processor.process(op.operationId)).rejects.toMatchObject({ retryable: true });
    const stored = await h.record(op.operationId);
    expect(stored.status).not.toBe('failed');
    expect(stored.status).not.toBe('ready');
    expect(h.resultDocs()).toBe(0);
    expect(await h.slots(op.operationId)).toHaveLength(3);
  });

  it('15 legacy single-photo Coffee and Palm valid readings still complete', async () => {
    for (const readingType of ['coffee', 'palm'] as const) {
      const body = readingType === 'palm'
        ? { visualObservation: 'v', overall: 'o', lifeLine: '', headLine: '', heartLine: '', fateLine: '', takeaway: '', symbols: [], themes: [] }
        : { ...VALID };
      const h = worker(async () => ({ ...body }));
      const op = await h.operations.create({
        ownerUserId: h.owner,
        readingType,
        sourceRequestId: `slice4c-legacy-${readingType}`,
      });
      await h.flow.remember(op);
      await h.stagedImages.stage({
        ownerUserId: h.owner,
        operationId: op.operationId,
        mimeType: 'image/jpeg',
        imageBase64: fakeJpeg(41_000).toString('base64'),
        ...(readingType === 'palm' ? { handSide: 'right' } : {}),
      });
      h.clock.ms = op.readyAtMs;
      expect(await h.processor.process(op.operationId)).toBe('completed');
      expect(h.resultDocs()).toBe(1);
    }
  });
});

describe('Slice 4C — real chain: fake provider → real V2 pipeline → real worker', () => {
  /** A gate-passing V2 observation whose evidence maps to no safe meaning. */
  const noMeaningObservation = (): CoffeeV2Observation => ({
    usable: true,
    reason: '',
    photoChecks: {
      cupPrimary: { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, usefulRegionsVisible: true },
      cupSecondary: { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, usefulRegionsVisible: true },
      saucer: { saucerVisible: true, adequateFocusLight: true, residueOrFlowVisible: false, usefulRegionsVisible: true },
    },
    evidence: [
      { id: 'e1', region: 'base', description: 'odd silhouette', resemblance: 'purple dragon', confidence: 'high', visibility: 'clear', sourceSlot: 'cup_primary' },
      { id: 'e2', region: 'rim', description: 'odd outline', resemblance: 'green teapot', confidence: 'high', visibility: 'clear', sourceSlot: 'cup_secondary' },
      { id: 'e3', region: 'base', description: 'odd smear', resemblance: 'silver comet', confidence: 'high', visibility: 'clear', sourceSlot: 'saucer' },
    ],
  });

  it('the real pipeline insufficient outcome reaches the seam and ends terminal', async () => {
    const seen: string[] = [];
    const fetchImpl = async (_url: unknown, init?: RequestInit) => {
      const body = JSON.parse(String(init?.body ?? '{}')) as { response_format?: { json_schema?: { name?: string } } };
      const name = body.response_format?.json_schema?.name ?? 'unknown';
      seen.push(name);
      if (name === 'coffee_v2_observation') {
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
    const op = await h.v2Op('real-chain');
    expect(await processor.process(op.operationId)).toBe('failed');
    expect(seen).toEqual(['coffee_v2_observation']); // observer only, no writer
    await expectTerminal(h, op.operationId, 'invalid');
    expect(await h.slots(op.operationId)).toEqual([]);
  });
});
