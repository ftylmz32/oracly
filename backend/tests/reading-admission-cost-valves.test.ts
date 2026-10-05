import { afterEach, describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import type { ServerClock } from '../src/reading/clock.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../src/reading/operation-staged-image-service.js';
import { FirestoreProviderStageRepository } from '../src/reading/provider-stage-repository.js';
import {
  DEFAULT_READING_ADMISSION_LIMITS,
  type ReadingAdmissionLimits,
} from '../src/reading/reading-admission.js';
import { ReadingFlow } from '../src/reading/reading-flow.js';
import { ReadingProcessor } from '../src/reading/reading-processor.js';
import { ReadingResultRepository } from '../src/reading/reading-result-repository.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import {
  StaticAppCheckVerifier,
  appCheckHeader,
  authHeader,
  fakeJpeg,
  signHs256,
  testApp,
  testConfig,
} from './helpers.js';

const SECRET = 'unit-test-jwt-secret';
const BURST_SIZE = 10;

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date { return new Date(this.ms); }
}

function headers(subject: string) {
  return {
    ...authHeader(signHs256(SECRET, { sub: subject })),
    ...appCheckHeader('good-token'),
  };
}

async function harness(limits: ReadingAdmissionLimits = DEFAULT_READING_ADMISSION_LIMITS) {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-10-05T10:00:00.000Z'));
  const policy = provisionalWaitPolicy({ coffee: 1_000, palm: 1_000 });
  const repository = new FirestoreReadingOperationRepository(store, limits);
  const operations = new ReadingOperationService(repository, clock, policy);
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
  const providerStages = new FirestoreProviderStageRepository(store);
  let providerCalls = 0;
  let schedulerCalls = 0;
  const processor = new ReadingProcessor(
    repository,
    flow,
    stagedRepository,
    stagedImages,
    results,
    {
      async handle() {
        providerCalls++;
        return { overall: 'cost-capable result', symbols: [], themes: [] };
      },
    },
    clock,
    undefined,
    false,
    providerStages,
  );
  const app = await testApp(
    testConfig({
      AI_JWT_SECRET: SECRET,
      AI_APP_CHECK_REQUIRED: 'true',
      AI_RATE_LIMIT_MAX: '2',
      AI_MAX_CONCURRENT: '1',
    }),
    async () => { throw new Error('real provider must not be called'); },
    {
      appCheck: new StaticAppCheckVerifier('good-token'),
      readingOperationRepository: repository,
      readingClock: clock,
      readingWaitPolicy: policy,
      readingFlow: flow,
      readingStagedImageRepository: stagedRepository,
      gemLedger: ledger,
      readingTaskScheduler: {
        async schedule() { schedulerCalls++; },
      },
    },
  );

  async function create(subject: string, readingType: 'coffee' | 'palm', sourceRequestId: string) {
    return app.inject({
      method: 'POST',
      url: '/v1/reading-operations',
      headers: headers(subject),
      payload: { readingType, sourceRequestId },
    });
  }

  async function stageAndProcess(subject: string, operationId: string, readingType: 'coffee' | 'palm') {
    const ownerUserId = identityKeyFromSubject(subject);
    await stagedImages.stage({
      ownerUserId,
      operationId,
      mimeType: 'image/jpeg',
      imageBase64: fakeJpeg().toString('base64'),
      ...(readingType === 'palm' ? { handSide: 'right' as const } : {}),
    });
    clock.ms += 1_000;
    return processor.process(operationId);
  }

  return {
    app,
    store,
    results,
    create,
    stageAndProcess,
    providerCalls: () => providerCalls,
    schedulerCalls: () => schedulerCalls,
  };
}

const openApps: Array<{ close(): Promise<void> }> = [];
afterEach(async () => {
  await Promise.all(openApps.splice(0).map((app) => app.close()));
});

async function setup(limits?: ReadingAdmissionLimits) {
  const h = await harness(limits);
  openApps.push(h.app);
  return h;
}

describe('reading admission / cost valves', () => {
  it('RED: one owner cannot turn ten distinct request ids into ten provider executions', async () => {
    const h = await setup();
    const responses = await Promise.all(
      Array.from({ length: BURST_SIZE }, (_, index) =>
        h.create('user-a', 'coffee', `wave35-burst-${index}`)),
    );
    const accepted = responses.filter((response) => response.statusCode === 200);
    const rejected = responses.filter((response) => response.statusCode !== 200);
    const operationIds = accepted.map((response) => response.json().data.operationId as string);
    const createdOperations = [...h.store.docs.keys()]
      .filter((key) => key.startsWith('readingOperations/'));

    for (const operationId of operationIds) {
      await h.stageAndProcess('user-a', operationId, 'coffee');
    }

    console.info('[WAVE3.5][cost-proof]', JSON.stringify({
      attempted: BURST_SIZE,
      accepted: accepted.length,
      rejected: rejected.length,
      operationsCreated: createdOperations.length,
      providerCalls: h.providerCalls(),
    }));
    expect(accepted).toHaveLength(DEFAULT_READING_ADMISSION_LIMITS.activeMaxPerIdentity);
    expect(rejected).toHaveLength(
      BURST_SIZE - DEFAULT_READING_ADMISSION_LIMITS.activeMaxPerIdentity,
    );
    expect(rejected.every((response) =>
      response.statusCode === 429 && response.json().error.code === 'rate_limited')).toBe(true);
    expect(createdOperations).toHaveLength(accepted.length);
    expect(h.providerCalls()).toBe(accepted.length);
    expect(h.schedulerCalls()).toBe(0);
    expect([...h.store.docs.values()].filter((doc) =>
      doc.type === 'spend' || doc.type === 'refund')).toHaveLength(0);
  });

  it('keeps sourceRequestId idempotency green for the same owner', async () => {
    const h = await setup();
    const first = await h.create('user-a', 'coffee', 'wave35-same-request');
    const second = await h.create('user-a', 'coffee', 'wave35-same-request');
    expect(first.statusCode).toBe(200);
    expect(second.statusCode).toBe(200);
    expect(second.json().data.operationId).toBe(first.json().data.operationId);
    expect([...h.store.docs.keys()].filter((key) => key.startsWith('readingOperations/'))).toHaveLength(1);
    await h.stageAndProcess('user-a', first.json().data.operationId, 'coffee');
    expect(await h.stageAndProcess('user-a', second.json().data.operationId, 'coffee')).toBe('noop');
    expect(h.providerCalls()).toBe(1);
  });

  it('does not block user B while user A creates a burst', async () => {
    const h = await setup();
    const burst = await Promise.all(
      Array.from({ length: BURST_SIZE }, (_, index) =>
        h.create('user-a', 'coffee', `wave35-isolation-a-${index}`)),
    );
    expect(burst.filter((response) => response.statusCode === 200)).toHaveLength(
      DEFAULT_READING_ADMISSION_LIMITS.activeMaxPerIdentity,
    );
    const userB = await h.create('user-b', 'palm', 'wave35-isolation-b');
    expect(userB.statusCode).toBe(200);
    expect(await h.stageAndProcess('user-b', userB.json().data.operationId, 'palm')).toBe('completed');
    expect(await h.results.get(userB.json().data.operationId)).not.toBeNull();
  });

  it.each(['coffee', 'palm'] as const)('keeps normal single %s usage green', async (readingType) => {
    const h = await setup();
    const response = await h.create('normal-user', readingType, `wave35-normal-${readingType}`);
    expect(response.statusCode).toBe(200);
    const operationId = response.json().data.operationId as string;
    expect(await h.stageAndProcess('normal-user', operationId, readingType)).toBe('completed');
    expect(await h.results.get(operationId)).not.toBeNull();
    expect(h.providerCalls()).toBe(1);
  });

  it('releases the owner slot at terminal state and applies the cap across reading types', async () => {
    const h = await setup({
      ...DEFAULT_READING_ADMISSION_LIMITS,
      activeMaxPerIdentity: 1,
    });
    const coffee = await h.create('terminal-user', 'coffee', 'wave36-terminal-coffee');
    const blockedPalm = await h.create('terminal-user', 'palm', 'wave36-blocked-palm');
    expect(coffee.statusCode).toBe(200);
    expect(blockedPalm.statusCode).toBe(429);
    expect([...h.store.docs.keys()].filter((key) => key.startsWith('readingOperations/'))).toHaveLength(1);
    expect(await h.stageAndProcess('terminal-user', coffee.json().data.operationId, 'coffee')).toBe('completed');
    const palm = await h.create('terminal-user', 'palm', 'wave36-after-terminal-palm');
    expect(palm.statusCode).toBe(200);
  });

  it('enforces the create-rate window after terminal operations release active slots', async () => {
    const limits = {
      ...DEFAULT_READING_ADMISSION_LIMITS,
      activeMaxPerIdentity: 1,
      createRateMax: 2,
    };
    const h = await setup(limits);
    for (let index = 0; index < limits.createRateMax; index++) {
      const response = await h.create('rate-user', 'coffee', `wave36-rate-${index}`);
      expect(response.statusCode).toBe(200);
      expect(await h.stageAndProcess('rate-user', response.json().data.operationId, 'coffee')).toBe('completed');
    }
    const rejected = await h.create('rate-user', 'coffee', 'wave36-rate-rejected');
    expect(rejected.statusCode).toBe(429);
    expect(rejected.json().error.code).toBe('rate_limited');
    expect([...h.store.docs.keys()].filter((key) => key.startsWith('readingOperations/'))).toHaveLength(2);
    expect(h.providerCalls()).toBe(2);
  });

  it('blocks a concurrent two-request bypass transactionally', async () => {
    const h = await setup({
      ...DEFAULT_READING_ADMISSION_LIMITS,
      activeMaxPerIdentity: 1,
    });
    const responses = await Promise.all([
      h.create('race-user', 'coffee', 'wave36-race-a'),
      h.create('race-user', 'palm', 'wave36-race-b'),
    ]);
    expect(responses.filter((response) => response.statusCode === 200)).toHaveLength(1);
    expect(responses.filter((response) => response.statusCode === 429)).toHaveLength(1);
    expect([...h.store.docs.keys()].filter((key) => key.startsWith('readingOperations/'))).toHaveLength(1);
    expect(h.providerCalls()).toBe(0);
    expect(h.schedulerCalls()).toBe(0);
  });
});
