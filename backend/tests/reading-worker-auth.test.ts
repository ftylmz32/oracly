import Fastify, { type FastifyRequest } from 'fastify';
import { describe, expect, it, vi } from 'vitest';
import {
  registerReadingWorkerRoutes,
  verifyCloudTask,
  type GoogleOidcVerifier,
} from '../src/routes/reading-worker-routes.js';
import { testConfig } from './helpers.js';

const audience = 'https://oracly-api-test.a.run.app';
const caller = 'runtime@oracly-test.iam.gserviceaccount.com';
const config = testConfig({
  READING_TASK_AUDIENCE: audience,
  READING_TASK_SERVICE_ACCOUNT: caller,
});
const request = (token = 'header.payload.signature') => ({
  headers: { authorization: `Bearer ${token}` },
  log: { info: vi.fn() },
}) as unknown as FastifyRequest;
const verifier = (payload?: Record<string, unknown>, rejection?: Error) => ({
  verifyIdToken: vi.fn(async (options: { audience: string | string[] }) => {
    expect(options.audience).toBe(audience);
    if (rejection) throw rejection;
    return { getPayload: () => payload };
  }),
}) as unknown as GoogleOidcVerifier;
const valid = {
  iss: 'https://accounts.google.com',
  aud: audience,
  email: caller,
  email_verified: true,
  sub: '1234567890',
};

describe('Cloud Tasks Google OIDC authentication', () => {
  it('accepts a cryptographically verified Google service-account token', async () => {
    await expect(verifyCloudTask(config, verifier(valid))(request())).resolves.toBe(true);
  });

  it.each([
    ['wrong audience', { ...valid, aud: 'https://wrong.example' }],
    ['wrong caller', { ...valid, email: 'other@oracly-test.iam.gserviceaccount.com' }],
    ['wrong issuer / Firebase user token', { ...valid, iss: 'https://securetoken.google.com/oracly-test' }],
    ['unverified email', { ...valid, email_verified: false }],
  ])('rejects %s', async (_label, payload) => {
    await expect(verifyCloudTask(config, verifier(payload))(request())).resolves.toBe(false);
  });

  it('rejects expired or cryptographically invalid tokens', async () => {
    await expect(verifyCloudTask(config, verifier(undefined, new Error('Token used too late')))(request()))
      .resolves.toBe(false);
  });

  it('rejects missing, malformed, and unsigned tokens', async () => {
    const check = verifyCloudTask(config, verifier(valid));
    await expect(check({ headers: {}, log: { info: vi.fn() } } as unknown as FastifyRequest))
      .resolves.toBe(false);
    await expect(check(request('malformed'))).resolves.toBe(false);
    await expect(check(request('header.payload.'))).resolves.toBe(false);
  });

  it('reaches the worker handler exactly once for one accepted delivery', async () => {
    const app = Fastify({ logger: false });
    const process = vi.fn().mockResolvedValue('noop');
    await registerReadingWorkerRoutes(app, config, {
      processor: { process } as never,
      verifyTask: async () => true,
    });
    const response = await app.inject({
      method: 'POST',
      url: '/internal/reading-tasks/process',
      payload: { operationId: '00000000000000000000000000000001' },
    });
    expect(response.statusCode).toBe(200);
    expect(process).toHaveBeenCalledOnce();
    await app.close();
  });
});
