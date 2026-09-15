import Fastify from 'fastify';
import { describe, expect, it, vi } from 'vitest';
import { ErrorCode } from '../src/errors.js';
import { registerReadingWorkerRoutes } from '../src/routes/reading-worker-routes.js';
import { ReadingWorkerFailure } from '../src/reading/reading-worker-telemetry.js';
import { chatBody, testApp, testConfig } from './helpers.js';

describe('global Fastify HTTP error semantics', () => {
  it('does not map thrown unknown errors to HTTP 200', async () => {
    const app = await testApp(testConfig());
    app.get('/__test/boom', async () => {
      throw new Error('unexpected_boom');
    });
    const res = await app.inject({ method: 'GET', url: '/__test/boom' });
    expect(res.statusCode).toBe(500);
    expect(res.json().error.code).toBe(ErrorCode.internalError);
    await app.close();
  });

  it('does not map malformed JSON to HTTP 200', async () => {
    const app = await testApp(testConfig());
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai',
      headers: { 'content-type': 'application/json' },
      payload: '{not-json',
    });
    expect(res.statusCode).not.toBe(200);
    expect(res.statusCode).toBeGreaterThanOrEqual(400);
    expect(res.statusCode).toBeLessThan(500);
    await app.close();
  });

  it('does not map auth rejection to HTTP 200', async () => {
    const app = await testApp(testConfig());
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: chatBody,
    });
    expect(res.statusCode).toBe(401);
    expect(res.statusCode).not.toBe(200);
    await app.close();
  });
});

describe('reading worker HTTP semantics', () => {
  const config = testConfig({
    READING_TASK_AUDIENCE: 'https://oracly-api-test.a.run.app',
    READING_TASK_SERVICE_ACCOUNT: 'runtime@oracly-test.iam.gserviceaccount.com',
  });

  it('returns retryable HTTP status for retryable worker failure', async () => {
    const app = Fastify({ logger: false });
    const process = vi.fn().mockRejectedValue(
      new ReadingWorkerFailure('staged_fetch_started', 'gcs_unavailable', true, 'palm'),
    );
    await registerReadingWorkerRoutes(app, config, {
      processor: { process } as never,
      verifyTask: async () => true,
    });
    const res = await app.inject({
      method: 'POST',
      url: '/internal/reading-tasks/process',
      payload: { operationId: '2d7e089de2e3f3e0eff40887bd2085fd' },
    });
    expect(res.statusCode).toBe(503);
    expect(res.statusCode).not.toBe(200);
    await app.close();
  });

  it('returns 2xx for successful completed/no-op task', async () => {
    const app = Fastify({ logger: false });
    const process = vi.fn().mockResolvedValue('noop');
    await registerReadingWorkerRoutes(app, config, {
      processor: { process } as never,
      verifyTask: async () => true,
    });
    const res = await app.inject({
      method: 'POST',
      url: '/internal/reading-tasks/process',
      payload: { operationId: '2d7e089de2e3f3e0eff40887bd2085fd' },
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().data.outcome).toBe('noop');
    await app.close();
  });

  it('returns 401 for auth rejection', async () => {
    const app = Fastify({ logger: false });
    await registerReadingWorkerRoutes(app, config, {
      processor: { process: vi.fn() } as never,
      verifyTask: async () => false,
    });
    const res = await app.inject({
      method: 'POST',
      url: '/internal/reading-tasks/process',
      payload: { operationId: '2d7e089de2e3f3e0eff40887bd2085fd' },
    });
    expect(res.statusCode).toBe(401);
    expect(res.statusCode).not.toBe(200);
    await app.close();
  });
});
