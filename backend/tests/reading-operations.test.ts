import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import type { ServerClock } from '../src/reading/clock.js';
import {
  StaticAppCheckVerifier,
  appCheckHeader,
  authHeader,
  chatBody,
  signHs256,
  testApp,
  testConfig,
} from './helpers.js';

const SECRET = 'unit-test-jwt-secret';
const SOURCE = 'req-coffee-01';

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date {
    return new Date(this.ms);
  }
  advance(ms: number): void {
    this.ms += ms;
  }
}

function harness(clock = new FixedClock(Date.parse('2026-09-08T00:00:00.000Z'))) {
  const store = new MemoryDocumentStore();
  const policy = provisionalWaitPolicy({
    coffee: 60_000,
    palm: 120_000,
    soulmate: 180_000,
  });
  const repository = new FirestoreReadingOperationRepository(store);
  return { store, clock, policy, repository };
}

async function appFor(setup = harness()) {
  const app = await testApp(
    testConfig({
      AI_JWT_SECRET: SECRET,
      AI_APP_CHECK_REQUIRED: 'true',
    }),
    async () => {
      throw new Error('reading operations must not call the AI provider');
    },
    {
      appCheck: new StaticAppCheckVerifier('good-token'),
      readingOperationRepository: setup.repository,
      readingClock: setup.clock,
      readingWaitPolicy: setup.policy,
    },
  );
  return { app, ...setup };
}

function headers(sub = 'user-a') {
  return {
    ...authHeader(signHs256(SECRET, { sub })),
    ...appCheckHeader('good-token'),
  };
}

async function createOp(
  app: Awaited<ReturnType<typeof appFor>>['app'],
  readingType: 'coffee' | 'palm' | 'soulmate',
  sourceRequestId = SOURCE,
  sub = 'user-a',
  extra: Record<string, unknown> = {},
) {
  return app.inject({
    method: 'POST',
    url: '/v1/reading-operations',
    headers: headers(sub),
    payload: { readingType, sourceRequestId, ...extra },
  });
}

describe('reading operations', () => {
  it('creates coffee, palm, and soulmate operations with server timestamps', async () => {
    const { app, clock, policy } = await appFor();
    for (const readingType of ['coffee', 'palm', 'soulmate'] as const) {
      const res = await createOp(app, readingType, `req-${readingType}-1`);
      expect(res.statusCode).toBe(200);
      const data = res.json().data;
      expect(data.readingType).toBe(readingType);
      expect(data.status).toBe('waiting');
      expect(data.createdAt).toBe(new Date(clock.ms).toISOString());
      expect(data.readyAt).toBe(
        new Date(clock.ms + policy.durationMs(readingType)).toISOString(),
      );
      expect(data.serverNow).toBe(new Date(clock.ms).toISOString());
      expect(data.waitFinished).toBe(false);
      expect(data.resultReady).toBe(false);
      expect(data.resultId).toBeNull();
      expect(data.ownerUserId).toBeUndefined();
      expect(data.failureCode).toBeUndefined();
      expect(data.gemDebitId).toBeUndefined();
    }
    await app.close();
  });

  it('rejects a client-supplied readyAt', async () => {
    const { app } = await appFor();
    const res = await createOp(app, 'coffee', SOURCE, 'user-a', {
      readyAt: '1999-01-01T00:00:00.000Z',
    });
    expect(res.statusCode).toBe(400);
    expect(res.json().error.code).toBe('invalid_request');
    await app.close();
  });

  it('reuses the same operation for the same idempotency key', async () => {
    const { app } = await appFor();
    const first = await createOp(app, 'palm', 'palm-key-01');
    const second = await createOp(app, 'palm', 'palm-key-01');
    expect(first.json().data.operationId).toBe(second.json().data.operationId);
    expect(second.json().data.createdAt).toBe(first.json().data.createdAt);
    await app.close();
  });

  it('rapid duplicate creates persist one operation', async () => {
    const { app, store } = await appFor();
    const results = await Promise.all([
      createOp(app, 'soulmate', 'soul-key-01'),
      createOp(app, 'soulmate', 'soul-key-01'),
      createOp(app, 'soulmate', 'soul-key-01'),
    ]);
    const ids = results.map((res) => res.json().data.operationId);
    expect(new Set(ids).size).toBe(1);
    const operations = [...store.docs.keys()].filter((key) =>
      key.startsWith('readingOperations/'),
    );
    expect(operations).toHaveLength(1);
    await app.close();
  });

  it('does not leak an operation across users sharing a source id', async () => {
    const { app } = await appFor();
    const a = await createOp(app, 'coffee', 'shared-key1', 'user-a');
    const b = await createOp(app, 'coffee', 'shared-key1', 'user-b');
    expect(a.json().data.operationId).not.toBe(b.json().data.operationId);
    const fetched = await app.inject({
      method: 'GET',
      url: `/v1/reading-operations/${a.json().data.operationId}`,
      headers: headers('user-b'),
    });
    expect(fetched.statusCode).toBe(404);
    expect(fetched.json().data).toBeUndefined();
    expect(fetched.json().error.code).toBe('invalid_request');
    await app.close();
  });

  it('hides another user operation including timestamps', async () => {
    const { app } = await appFor();
    const created = await createOp(app, 'palm', 'palm-own-01', 'user-a');
    const denied = await app.inject({
      method: 'GET',
      url: `/v1/reading-operations/${created.json().data.operationId}`,
      headers: headers('user-b'),
    });
    expect(denied.statusCode).toBe(404);
    expect(JSON.stringify(denied.json())).not.toContain('readyAt');
    await app.close();
  });

  it('survives repository reconstruction on the same durable store', async () => {
    const setup = harness();
    const { app } = await appFor(setup);
    const created = await createOp(app, 'coffee', 'persist-key1');
    const operationId = created.json().data.operationId as string;
    await app.close();
    const rebuilt = new ReadingOperationService(
      new FirestoreReadingOperationRepository(setup.store),
      setup.clock,
      setup.policy,
    );
    const record = await rebuilt.get(
      identityKeyFromSubject('user-a'),
      operationId,
    );
    expect(record.operationId).toBe(operationId);
    expect(record.readyAtMs).toBe(setup.clock.ms + 60_000);
  });

  it('ignores device clock values and keeps server readyAt', async () => {
    const { app, clock, policy } = await appFor();
    const res = await app.inject({
      method: 'POST',
      url: '/v1/reading-operations',
      headers: {
        ...headers('user-a'),
        date: 'Mon, 01 Jan 1990 00:00:00 GMT',
        'x-client-now': '1990-01-01T00:00:00.000Z',
      },
      payload: {
        readingType: 'coffee',
        sourceRequestId: 'clock-key-01',
      },
    });
    expect(res.json().data.createdAt).toBe(new Date(clock.ms).toISOString());
    expect(res.json().data.readyAt).toBe(
      new Date(clock.ms + policy.durationMs('coffee')).toISOString(),
    );
    await app.close();
  });

  it('does not mark result ready when the wait elapses', async () => {
    const setup = harness();
    const { app } = await appFor(setup);
    const created = await createOp(app, 'soulmate', 'wait-key-001');
    setup.clock.advance(180_000);
    const status = await app.inject({
      method: 'GET',
      url: `/v1/reading-operations/${created.json().data.operationId}`,
      headers: headers('user-a'),
    });
    const data = status.json().data;
    expect(data.waitFinished).toBe(true);
    expect(data.remainingMs).toBe(0);
    expect(data.status).toBe('waiting');
    expect(data.resultReady).toBe(false);
    expect(data.resultId).toBeNull();
    await app.close();
  });

  it('attaches one result, rejects a conflicting result, and ignores stale failure', async () => {
    const setup = harness();
    const owner = identityKeyFromSubject('user-a');
    const service = new ReadingOperationService(
      setup.repository,
      setup.clock,
      setup.policy,
    );
    const created = await service.create({
      ownerUserId: owner,
      readingType: 'coffee',
      sourceRequestId: 'attach-key1',
    });
    const ready = await service.attachResult({
      ownerUserId: owner,
      operationId: created.operationId,
      resultId: 'result-id-1',
    });
    expect(ready.status).toBe('ready');
    const again = await service.attachResult({
      ownerUserId: owner,
      operationId: created.operationId,
      resultId: 'result-id-1',
    });
    expect(again.resultId).toBe('result-id-1');
    await expect(
      service.attachResult({
        ownerUserId: owner,
        operationId: created.operationId,
        resultId: 'result-id-2',
      }),
    ).rejects.toMatchObject({ code: 'conflict' });
    await expect(
      service.fail({
        ownerUserId: owner,
        operationId: created.operationId,
        failureCode: 'unavailable',
      }),
    ).rejects.toMatchObject({ code: 'conflict' });
    expect(
      (await service.get(owner, created.operationId)).status,
    ).toBe('ready');
    await expect(
      service.attachResult({
        ownerUserId: identityKeyFromSubject('user-b'),
        operationId: created.operationId,
        resultId: 'result-id-1',
      }),
    ).rejects.toMatchObject({ code: 'not_found' });
  });

  it('exposes allow-listed failureCode on failed status only', async () => {
    const setup = harness();
    const { app } = await appFor(setup);
    const invalid = await app.inject({
      method: 'POST',
      url: '/v1/reading-operations',
      headers: headers('user-a'),
      payload: { readingType: 'tarot', sourceRequestId: SOURCE },
    });
    expect(invalid.statusCode).toBe(400);
    const owner = identityKeyFromSubject('user-a');
    const service = new ReadingOperationService(
      setup.repository,
      setup.clock,
      setup.policy,
    );
    const created = await service.create({
      ownerUserId: owner,
      readingType: 'palm',
      sourceRequestId: 'fail-key-001',
    });
    await service.fail({
      ownerUserId: owner,
      operationId: created.operationId,
      failureCode: 'unavailable',
    });
    const status = await app.inject({
      method: 'GET',
      url: `/v1/reading-operations/${created.operationId}`,
      headers: headers('user-a'),
    });
    const body = JSON.stringify(status.json());
    expect(status.json().data.status).toBe('failed');
    expect(status.json().data.failureCode).toBe('unavailable');
    expect(body).not.toContain('provider');
    expect(body).not.toContain('ownerUserId');
    await app.close();
  });

  it('has no acceleration bypass and leaves existing AI complete untouched', async () => {
    const setup = harness();
    const created = await new ReadingOperationService(
      setup.repository,
      setup.clock,
      setup.policy,
    ).create({
      ownerUserId: identityKeyFromSubject('user-a'),
      readingType: 'coffee',
      sourceRequestId: 'accel-key-01',
    });
    const app = await testApp(
      testConfig({
        AI_JWT_SECRET: SECRET,
        AI_APP_CHECK_REQUIRED: 'true',
      }),
      async () =>
        new Response(
          JSON.stringify({
            choices: [{ message: { content: 'Sakin bir nefes.' } }],
          }),
          { status: 200, headers: { 'content-type': 'application/json' } },
        ),
      {
        appCheck: new StaticAppCheckVerifier('good-token'),
        readingOperationRepository: setup.repository,
        readingClock: setup.clock,
        readingWaitPolicy: setup.policy,
      },
    );
    const accelerate = await app.inject({
      method: 'POST',
      url: `/v1/reading-operations/${created.operationId}/accelerate`,
      headers: headers('user-a'),
      payload: { readyAt: '2020-01-01T00:00:00.000Z' },
    });
    expect(accelerate.statusCode).toBe(503);
    expect(accelerate.json().error.code).toBe('no_configuration');
    const status = await app.inject({
      method: 'GET',
      url: `/v1/reading-operations/${created.operationId}`,
      headers: headers('user-a'),
    });
    expect(status.json().data.readyAt).toBe(
      new Date(setup.clock.ms + 60_000).toISOString(),
    );
    expect(status.json().data.status).toBe('waiting');
    const ai = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: headers('user-a'),
      payload: chatBody,
    });
    expect(ai.json().success).toBe(true);
    await app.close();
  });

  it('requires auth and app check, and fails closed without a durable store', async () => {
    const closed = await testApp(
      testConfig({
        AI_JWT_SECRET: SECRET,
        AI_APP_CHECK_REQUIRED: 'true',
      }),
      async () => {
        throw new Error('must not call AI');
      },
      { appCheck: new StaticAppCheckVerifier('good-token') },
    );
    const denied = await createOp(closed, 'coffee', 'closed-key01');
    expect(denied.statusCode).toBe(503);
    expect(denied.json().error.code).toBe('no_configuration');
    await closed.close();

    const { app } = await appFor();
    const noAuth = await app.inject({
      method: 'POST',
      url: '/v1/reading-operations',
      headers: { ...appCheckHeader('good-token'), 'content-type': 'application/json' },
      payload: { readingType: 'coffee', sourceRequestId: SOURCE },
    });
    expect(noAuth.statusCode).toBe(401);
    const noCheck = await app.inject({
      method: 'POST',
      url: '/v1/reading-operations',
      headers: authHeader(signHs256(SECRET, { sub: 'user-a' })),
      payload: { readingType: 'coffee', sourceRequestId: SOURCE },
    });
    expect(noCheck.statusCode).toBe(401);
    expect(noCheck.json().error.code).toBe('app_check_required');
    await app.close();
  });
});
