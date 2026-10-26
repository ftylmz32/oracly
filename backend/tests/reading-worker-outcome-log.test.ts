/**
 * Büyük Final Aşama 01 / F1, option A — the worker route records what the
 * processor returned for each delivery it ran, as one structured info event:
 *
 *   { event: 'reading_task_outcome', operationId, outcome }
 *
 * Nothing else: no owner, no reading content, no gem data. HTTP status,
 * response body, the error branch and retries are unchanged. One event per
 * delivery attempt: a redelivered task logs again. Unauthorized and invalid
 * requests, and thrown failures (which keep their own failure telemetry),
 * log no outcome.
 *
 * Scope: this makes a silent `failed` visible; it does not say why. A
 * daily_quota failure shows as `outcome: failed`, so the quota-specific
 * F1 observability test stays an expected failure.
 */
import Fastify from 'fastify';
import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { successEnvelope } from '../src/errors.js';
import { ReadingWorkerFailure } from '../src/reading/reading-worker-telemetry.js';
import { registerReadingWorkerRoutes } from '../src/routes/reading-worker-routes.js';
import { world } from './support/coffee-quota-world.js';
import { testConfig } from './helpers.js';

const OP = '0123456789abcdef0123456789abcdef';
const BASE_KEYS = ['hostname', 'level', 'pid', 'reqId', 'time'];

async function routeWith(
  process: (operationId: string, log: unknown) => Promise<unknown>,
  options: { authorized?: boolean } = {},
) {
  const lines: Array<Record<string, unknown>> = [];
  const app = Fastify({
    logger: {
      level: 'info',
      stream: { write: (line: string) => void lines.push(JSON.parse(line)) },
    },
  });
  let calls = 0;
  await registerReadingWorkerRoutes(app, testConfig(), {
    processor: {
      process: async (operationId: string, log: unknown) => {
        calls += 1;
        return process(operationId, log);
      },
    } as never,
    verifyTask: async () => options.authorized ?? true,
  });
  const post = (payload: unknown) =>
    app.inject({ method: 'POST', url: '/internal/reading-tasks/process', payload: payload as never });
  const outcomes = () => lines.filter((l) => l.event === 'reading_task_outcome');
  return { app, post, outcomes, lines, calls: () => calls };
}

describe('reading_task_outcome: one event per processed delivery', () => {
  for (const outcome of ['completed', 'noop', 'staged_ok', 'failed', 'owner_deleted']) {
    it(`${outcome}: logged with operationId and outcome only; response unchanged`,
      async () => {
        const r = await routeWith(async () => outcome);
        const res = await r.post({ operationId: OP });
        expect(res.statusCode).toBe(200);
        expect(res.json()).toEqual(successEnvelope({ outcome }));
        const events = r.outcomes();
        expect(events).toHaveLength(1);
        expect(events[0]).toMatchObject({ level: 30, operationId: OP, outcome });
        const extra = Object.keys(events[0])
          .filter((k) => !BASE_KEYS.includes(k))
          .sort();
        expect(extra).toEqual(['event', 'operationId', 'outcome']);
        await r.app.close();
      });
  }

  it('a redelivered task logs once per attempt', async () => {
    const r = await routeWith(async () => 'noop');
    await r.post({ operationId: OP });
    await r.post({ operationId: OP });
    expect(r.calls()).toBe(2);
    expect(r.outcomes()).toHaveLength(2);
    await r.app.close();
  });
});

describe('no outcome event where nothing was processed', () => {
  it('unauthorized: 401, processor not called, no event', async () => {
    const r = await routeWith(async () => 'completed', { authorized: false });
    const res = await r.post({ operationId: OP });
    expect(res.statusCode).toBe(401);
    expect(r.calls()).toBe(0);
    expect(r.outcomes()).toHaveLength(0);
    await r.app.close();
  });

  it('invalid body: 400, processor not called, no event', async () => {
    const r = await routeWith(async () => 'completed');
    const res = await r.post({ operationId: 42 });
    expect(res.statusCode).toBe(400);
    expect(r.calls()).toBe(0);
    expect(r.outcomes()).toHaveLength(0);
    await r.app.close();
  });

  it('a thrown retryable failure keeps 503 and its failure telemetry, no '
    + 'outcome event', async () => {
    const r = await routeWith(async () => {
      throw new ReadingWorkerFailure('provider_started', 'provider_unavailable', true, 'coffee');
    });
    const res = await r.post({ operationId: OP });
    expect(res.statusCode).toBe(503);
    expect(r.outcomes()).toHaveLength(0);
    expect(r.lines.some((l) => l.level === 50 && l.operationId === OP)).toBe(true);
    await r.app.close();
  });
});

describe('F1 through the route: quota already used, accelerated with gems', () => {
  it('the silent daily_quota failure now shows as outcome failed; gems and '
    + 'state unchanged by the logging', async () => {
    const w = await world();
    const owner = identityKeyFromSubject('f1-route-owner');
    await w.useTodaysCoffee(owner);
    const opId = await w.acceleratedCoffee(owner, 'route1');
    const r = await routeWith((id, log) => w.processor.process(id, log as never));
    const res = await r.post({ operationId: opId });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual(successEnvelope({ outcome: 'failed' }));
    expect(r.outcomes()).toEqual([
      expect.objectContaining({ operationId: opId, outcome: 'failed' }),
    ]);
    // Same economics as the F1 lifecycle test.
    expect(w.calls()).toBe(0);
    expect((await w.operations.get(owner, opId)).failureCode).toBe('daily_quota');
    expect(w.transactionsFor(opId)).toEqual(['refund', 'spend']);
    // The event says failed, not why: no failure code, no owner.
    const text = JSON.stringify(r.outcomes());
    expect(text).not.toContain('daily_quota');
    expect(text).not.toContain(owner);
    await r.app.close();
  });
});
