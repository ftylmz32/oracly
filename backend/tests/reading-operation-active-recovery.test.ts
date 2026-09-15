/**
 * Regression coverage for a real-device-confirmed wiring bug: `server.ts`
 * built `registerReadingOperationRoutes` (the `POST /v1/reading-operations`
 * create route) WITHOUT passing it the `flow` option, so `flow?.remember()`
 * was always a silent no-op — the `readingOperationActive` pointer
 * `registerReadingFlowRoutes`'s `GET /v1/reading-flow/active` route reads
 * back was never written, in every environment, for every reading type.
 *
 * Every existing test exercised `ReadingFlow.remember()`/`.active()`
 * directly (see reading-flow.test.ts) — none went through the real HTTP
 * create route the way a live client does, so this was invisible until a
 * genuine on-device app-restart-during-`waiting` test: a Coffee operation
 * was created and staged successfully, but after killing and relaunching
 * the app, recovery found nothing to resume — not because the client-side
 * recovery logic was wrong, but because the server had never remembered
 * the operation was active in the first place.
 *
 * This test goes through the SAME real `buildServer()` wiring `index.ts`
 * uses (via `testApp`), not a hand-constructed `ReadingFlow`, so a
 * regression back to the missing `flow` option fails this test exactly
 * the way it failed on the real device.
 */
import { describe, expect, it } from 'vitest';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { ReadingFlow } from '../src/reading/reading-flow.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import type { ServerClock } from '../src/reading/clock.js';
import {
  StaticAppCheckVerifier,
  appCheckHeader,
  authHeader,
  signHs256,
  testApp,
  testConfig,
} from './helpers.js';

const SECRET = 'unit-test-jwt-secret';

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date {
    return new Date(this.ms);
  }
  advance(ms: number): void {
    this.ms += ms;
  }
}

function headers(sub = 'user-a') {
  return {
    ...authHeader(signHs256(SECRET, { sub })),
    ...appCheckHeader('good-token'),
  };
}

async function harness() {
  const clock = new FixedClock(Date.parse('2026-09-08T00:00:00.000Z'));
  const store = new MemoryDocumentStore();
  const policy = provisionalWaitPolicy({ coffee: 60_000, palm: 60_000, soulmate: 60_000 });
  const repository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(repository, clock, policy);
  const ledger = new GemLedger(store, clock, provisionalGemCostPolicy({ coffee: 10 }));
  const flow = new ReadingFlow(store, clock, operations, ledger);
  const app = await testApp(
    testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' }),
    async () => {
      throw new Error('this test must never call the AI provider');
    },
    {
      appCheck: new StaticAppCheckVerifier('good-token'),
      readingOperationRepository: repository,
      readingClock: clock,
      readingWaitPolicy: policy,
      readingFlow: flow,
      gemLedger: ledger,
    },
  );
  return { app, clock, flow };
}

describe('server.ts wiring: create -> active recovery, through real HTTP', () => {
  it(
    'a freshly-created operation is immediately visible via GET ' +
      '/v1/reading-flow/active — proves POST /v1/reading-operations ' +
      'actually calls flow.remember() through the real route, not just ' +
      'in a unit test that calls it directly',
    async () => {
      const { app } = await harness();
      const created = await app.inject({
        method: 'POST',
        url: '/v1/reading-operations',
        headers: headers(),
        payload: { readingType: 'coffee', sourceRequestId: 'recovery-src-01' },
      });
      expect(created.statusCode).toBe(200);
      const operationId = created.json().data.operationId as string;
      expect(operationId).toBeTruthy();

      const active = await app.inject({
        method: 'GET',
        url: '/v1/reading-flow/active?readingType=coffee',
        headers: headers(),
      });
      expect(active.statusCode).toBe(200);
      const operation = active.json().data.operation;
      expect(
        operation,
        'THE BUG: this was null — the create route never remembered the ' +
          'operation as active, so recovery could never find it, even ' +
          'though it was created (and, in the live app, staged) ' +
          'successfully seconds earlier',
      ).not.toBeNull();
      expect(operation.operationId).toBe(operationId);
      expect(operation.status).toBe('waiting');
      await app.close();
    },
  );

  it('the active pointer still resolves after the wait elapses and stays claimable', async () => {
    // Soulmate: claim has no staged-image precondition (unlike
    // coffee/palm — see reading-staged-image.test.ts for that separate
    // concern), so this test stays focused purely on the active-pointer
    // wiring + eligibility-after-wait behavior.
    const { app, clock } = await harness();
    const created = await app.inject({
      method: 'POST',
      url: '/v1/reading-operations',
      headers: headers(),
      payload: { readingType: 'soulmate', sourceRequestId: 'recovery-src-02' },
    });
    const operationId = created.json().data.operationId as string;

    clock.advance(60_000);

    const active = await app.inject({
      method: 'GET',
      url: '/v1/reading-flow/active?readingType=soulmate',
      headers: headers(),
    });
    expect(active.json().data.operation.waitFinished).toBe(true);

    const claim = await app.inject({
      method: 'POST',
      url: `/v1/reading-operations/${operationId}/claim`,
      headers: headers(),
      payload: {},
    });
    expect(claim.statusCode).toBe(200);
    expect(claim.json().data.execute).toBe(true);
    await app.close();
  });

  it('a different owner never sees another user\'s active operation', async () => {
    const { app } = await harness();
    await app.inject({
      method: 'POST',
      url: '/v1/reading-operations',
      headers: headers('user-a'),
      payload: { readingType: 'coffee', sourceRequestId: 'recovery-src-03' },
    });

    const active = await app.inject({
      method: 'GET',
      url: '/v1/reading-flow/active?readingType=coffee',
      headers: headers('user-b'),
    });
    expect(active.statusCode).toBe(200);
    expect(active.json().data.operation).toBeNull();
    await app.close();
  });
});
