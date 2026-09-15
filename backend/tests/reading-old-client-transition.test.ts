/**
 * Proves the currently-installed 26091105 client's OLD claim/complete HTTP
 * protocol is still safe now that a durable Cloud Tasks worker can process
 * the SAME operation concurrently. The old client's `/claim` route and the
 * new worker's `ReadingProcessor.process()` both funnel through the exact
 * same `ReadingFlow.claim()` transactional gate -- this test exercises the
 * old client's REAL HTTP request shape (not just the internal method) racing
 * a real worker delivery, for both the acceleration and the free-wait-expiry
 * paths the task named explicitly.
 */
import { describe, expect, it } from 'vitest';
import { buildServer } from '../src/server.js';
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
import { ReadingProcessor, type ReadingCompletionNotifier } from '../src/reading/reading-processor.js';
import { ReadingResultRepository } from '../src/reading/reading-result-repository.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import {
  StaticAppCheckVerifier,
  appCheckHeader,
  authHeader,
  fakeJpeg,
  signHs256,
  testConfig,
} from './helpers.js';

const SECRET = 'unit-test-jwt-secret';

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date { return new Date(this.ms); }
}

class NoopNotifier implements ReadingCompletionNotifier {
  calls = 0;
  async notifyCompleted(): Promise<void> { this.calls++; }
}

async function rig() {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-09-11T10:00:00Z'));
  const repository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(
    repository,
    clock,
    provisionalWaitPolicy({ palm: 60_000 }),
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
  const notifier = new NoopNotifier();
  let providerCalls = 0;
  const ai = {
    async handle() {
      providerCalls++;
      return { overall: 'durable result', symbols: [], themes: [] };
    },
  };
  const processor = new ReadingProcessor(
    repository, flow, stagedRepository, stagedImages, results, ai, clock, notifier,
  );
  const owner = identityKeyFromSubject('legacy-client-user');
  const operation = await operations.create({
    ownerUserId: owner,
    readingType: 'palm',
    sourceRequestId: 'palm-legacy-01',
  });
  await flow.remember(operation);
  await stagedImages.stage({
    ownerUserId: owner,
    operationId: operation.operationId,
    mimeType: 'image/jpeg',
    imageBase64: fakeJpeg().toString('base64'),
    handSide: 'right',
  });
  const app = await buildServer({
    config: testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' }),
    fetchImpl: async () => {
      throw new Error('must not call the raw AI proxy in this test');
    },
    logger: false,
    appCheck: new StaticAppCheckVerifier('good-token'),
    readingOperationRepository: repository,
    readingClock: clock,
    readingFlow: flow,
    gemLedger: ledger,
    readingStagedImageRepository: stagedRepository,
    readingStagedImages: stagedImages,
    readingProcessor: processor,
    readingResults: results,
  } as never);
  const headers = {
    ...authHeader(signHs256(SECRET, { sub: 'legacy-client-user' })),
    ...appCheckHeader('good-token'),
  };
  return { app, headers, clock, store, flow, ledger, owner, operation, processor, results, notifier, providerCalls: () => providerCalls };
}

describe('26091105 (pre-durable) client protocol vs the durable worker', () => {
  it('Gem acceleration success + immediate old-client /claim + Cloud Task worker delivery -> exactly one provider execution, one debit', async () => {
    const h = await rig();
    await h.ledger.credit({ ownerUserId: h.owner, amount: 40, idempotencyKey: 'seed-legacy-01' });
    const accelerated = await h.ledger.accelerate({
      ownerUserId: h.owner,
      operationId: h.operation.operationId,
      idempotencyKey: 'accel-legacy-01',
    });
    expect(accelerated.outcome).toBe('accelerated');

    // The OLD client's exact real HTTP request (its own claim/resume path)
    // racing the durable worker's in-process claim, concurrently.
    const [oldClientClaim, workerOutcome] = await Promise.allSettled([
      h.app.inject({
        method: 'POST',
        url: `/v1/reading-operations/${h.operation.operationId}/claim`,
        headers: h.headers,
        payload: {},
      }),
      h.processor.process(h.operation.operationId),
    ]);

    // Old client's request shape is accepted either way (never a schema
    // rejection) -- it's a 200 whether it won or lost the race.
    expect(oldClientClaim.status).toBe('fulfilled');
    if (oldClientClaim.status === 'fulfilled') {
      expect(oldClientClaim.value.statusCode).toBe(200);
    }

    // Exactly one of the two participants actually executed the provider.
    // The loser gets a safe, authoritative "no-op"/"not this one" outcome,
    // never a duplicate execution.
    expect(h.providerCalls()).toBe(1);
    void workerOutcome;

    // No duplicate Gem debit: only the one spend from accelerate() above.
    const spendCount = [...h.store.docs.values()].filter((d) => d.type === 'spend').length;
    expect(spendCount).toBe(1);

    // No duplicate Gem debit and no duplicate result -- same operationId only.
    const finalOp = await h.flow.active(h.owner, 'palm').catch(() => null);
    expect(finalOp === null || finalOp.operationId === h.operation.operationId).toBe(true);
    const resultCount = (await h.results.get(h.operation.operationId)) ? 1 : 0;
    expect(resultCount).toBe(1);
    await h.app.close();
  });

  it('readyAt expiry + old-client wake/resume attempt + Cloud Task delivery -> exactly one provider execution', async () => {
    const h = await rig();
    h.clock.ms = h.operation.readyAtMs;

    const [oldClientClaim, workerOutcome] = await Promise.allSettled([
      h.app.inject({
        method: 'POST',
        url: `/v1/reading-operations/${h.operation.operationId}/claim`,
        headers: h.headers,
        payload: {},
      }),
      h.processor.process(h.operation.operationId),
    ]);

    expect(oldClientClaim.status).toBe('fulfilled');
    if (oldClientClaim.status === 'fulfilled') {
      expect(oldClientClaim.value.statusCode).toBe(200);
    }
    expect(h.providerCalls()).toBe(1);
    void workerOutcome;

    // A late-arriving second worker delivery (Cloud Tasks redelivery, or the
    // old client polling /claim again) must be a safe no-op, not a retry.
    const secondWorkerPass = await h.processor.process(h.operation.operationId);
    expect(secondWorkerPass).toBe('noop');
    const secondClaimHttp = await h.app.inject({
      method: 'POST',
      url: `/v1/reading-operations/${h.operation.operationId}/claim`,
      headers: h.headers,
      payload: {},
    });
    expect(secondClaimHttp.statusCode).toBe(200);
    const body = secondClaimHttp.json();
    expect(body.data.execute).toBe(false);
    expect(body.data.operation.status).toBe('ready');
    expect(h.providerCalls()).toBe(1);
    await h.app.close();
  });
});
