/**
 * #44 — the acknowledgement retry runs on its own `billing-acknowledge`
 * queue and OIDC identity, never the reading queue. Nothing is lost
 * silently: a task that cannot be created marks the entry, a sweep
 * (Cloud Scheduler) re-creates tasks that never ran, and overdue or
 * abandoned entries surface as countable, alertable events. Only the
 * billing task identity can drive either endpoint.
 */
import { describe, expect, it } from 'vitest';
import {
  ACK_LOST_GRACE_MS,
  ACK_OVERDUE_MS,
  ACK_RETRY_DELAYS_MS,
  CloudTasksAckRetryScheduler,
  InMemoryAckOutbox,
  createAckRetryScheduler,
  type AckOutboxEntry,
  type AckRetryScheduler,
} from '../src/billing/ack-outbox.js';
import { verifyBillingTask } from '../src/billing/billing-task-auth.js';
import { billingResult, type StoreVerifier } from '../src/billing/types.js';
import { signHs256, testApp, testConfig } from './helpers.js';

const MONTHLY = 'app.oracly.premium.monthly';

const BILLING_QUEUE_ENV = {
  FIREBASE_PROJECT_ID: 'oracly-7f613',
  BILLING_ACK_QUEUE: 'billing-acknowledge',
  BILLING_ACK_LOCATION: 'europe-west1',
  BILLING_ACK_TARGET_URL:
    'https://oracly-api-x.a.run.app/internal/billing/acknowledge-retry',
  BILLING_ACK_AUDIENCE: 'https://oracly-api-x.a.run.app',
  BILLING_ACK_SERVICE_ACCOUNT: 'oracly-billing-tasks@oracly-7f613.iam.gserviceaccount.com',
};

const READING_ONLY_ENV = {
  FIREBASE_PROJECT_ID: 'oracly-7f613',
  READING_TASK_QUEUE: 'reading-operations',
  READING_TASK_TARGET_URL:
    'https://oracly-api-x.a.run.app/internal/reading-tasks/process',
  READING_TASK_AUDIENCE: 'https://oracly-api-x.a.run.app',
  READING_TASK_SERVICE_ACCOUNT: 'oracly-api-runtime@oracly-7f613.iam.gserviceaccount.com',
};

describe('a dedicated billing-acknowledge queue', () => {
  it('reads its own BILLING_ACK_* settings', () => {
    const config = testConfig(BILLING_QUEUE_ENV);
    expect(config.billingAckQueue).toBe('billing-acknowledge');
    expect(config.billingAckLocation).toBe('europe-west1');
    expect(config.billingAckTargetUrl).toBe(BILLING_QUEUE_ENV.BILLING_ACK_TARGET_URL);
    expect(config.billingAckAudience).toBe(BILLING_QUEUE_ENV.BILLING_ACK_AUDIENCE);
    expect(config.billingAckServiceAccount).toBe(
      BILLING_QUEUE_ENV.BILLING_ACK_SERVICE_ACCOUNT,
    );
  });

  it('creates tasks only on the billing queue, with the billing identity',
    async () => {
      const requests: Array<{ url: string; data: any }> = [];
      const scheduler = new CloudTasksAckRetryScheduler(
        testConfig(BILLING_QUEUE_ENV),
        { request: async (r: { url: string; data: any }) => { requests.push(r); return {}; } } as never,
      );
      await scheduler.schedule({ id: 'abc', attempt: 2, atMs: 1_800_000_000_000 });
      expect(requests).toHaveLength(1);
      expect(requests[0].url).toContain(
        'projects/oracly-7f613/locations/europe-west1/queues/billing-acknowledge/tasks',
      );
      const task = requests[0].data.task;
      expect(task.name).toContain('/queues/billing-acknowledge/tasks/billing-ack-abc-2');
      expect(task.httpRequest.url).toBe(BILLING_QUEUE_ENV.BILLING_ACK_TARGET_URL);
      expect(task.httpRequest.oidcToken).toEqual({
        serviceAccountEmail: BILLING_QUEUE_ENV.BILLING_ACK_SERVICE_ACCOUNT,
        audience: BILLING_QUEUE_ENV.BILLING_ACK_AUDIENCE,
      });
    });

  it('a sweep re-creation gets its own task name: a tombstoned name cannot '
    + 'swallow it as a duplicate', async () => {
      const requests: Array<{ url: string; data: any }> = [];
      const scheduler = new CloudTasksAckRetryScheduler(
        testConfig(BILLING_QUEUE_ENV),
        { request: async (r: { url: string; data: any }) => { requests.push(r); return {}; } } as never,
      );
      await scheduler.schedule({ id: 'abc', attempt: 2, atMs: 1, key: 's99' });
      expect(requests[0].data.task.name).toMatch(/\/tasks\/billing-ack-abc-2-s99$/);
    });

  it('never falls back to the reading queue: unconfigured scheduling fails '
    + 'loudly', async () => {
    const scheduler = createAckRetryScheduler(testConfig(READING_ONLY_ENV));
    await expect(
      scheduler.schedule({ id: 'abc', attempt: 0, atMs: 1 }),
    ).rejects.toThrow('ack_retry_scheduler_unconfigured');
  });
});

describe('only the billing task identity drives billing task endpoints', () => {
  const oauthReturning = (payload: Record<string, unknown> | Error) => ({
    verifyIdToken: async () => {
      if (payload instanceof Error) throw payload;
      return { getPayload: () => payload };
    },
  });
  const request = (authorization?: string) =>
    ({ headers: authorization ? { authorization } : {} }) as never;
  const config = testConfig(BILLING_QUEUE_ENV);
  const good = {
    iss: 'https://accounts.google.com',
    email: BILLING_QUEUE_ENV.BILLING_ACK_SERVICE_ACCOUNT,
    email_verified: true,
  };

  it('accepts the billing service account', async () => {
    expect(await verifyBillingTask(config, oauthReturning(good) as never)(
      request('Bearer a.b.c'),
    )).toBe(true);
  });

  it('refuses no token, the reading identity and a bad signature', async () => {
    expect(await verifyBillingTask(config, oauthReturning(good) as never)(request())).toBe(false);
    expect(await verifyBillingTask(config, oauthReturning({
      ...good,
      email: READING_ONLY_ENV.READING_TASK_SERVICE_ACCOUNT,
    }) as never)(request('Bearer a.b.c'))).toBe(false);
    expect(await verifyBillingTask(config, oauthReturning(new Error('bad')) as never)(
      request('Bearer a.b.c'),
    )).toBe(false);
  });

  it('refuses everything when the billing identity is not configured', async () => {
    expect(await verifyBillingTask(
      testConfig(READING_ONLY_ENV),
      oauthReturning(good) as never,
    )(request('Bearer a.b.c'))).toBe(false);
  });
});

describe('no acknowledgement is lost silently', () => {
  const authedConfig = () =>
    testConfig({
      AI_DEV_AUTH_BYPASS: 'false',
      AI_AUTH_REQUIRED: 'true',
      AI_JWT_SECRET: 'billing-test-secret',
      AI_JWT_ISSUER: 'https://issuer.example',
      AI_JWT_AUDIENCE: 'oracly-ai',
      FIREBASE_PROJECT_ID: '',
      AI_JWKS_URL: '',
    });
  const bearer = signHs256('billing-test-secret', {
    sub: 'user-a',
    iss: 'https://issuer.example',
    aud: 'oracly-ai',
  });

  class Scheduler implements AckRetryScheduler {
    fail = false;
    readonly scheduled: Array<{ id: string; attempt: number; atMs: number; key?: string }> = [];
    async schedule(input: { id: string; attempt: number; atMs: number; key?: string }) {
      if (this.fail) throw new Error('cloud tasks down');
      this.scheduled.push(input);
    }
  }

  async function harness(taskVerified = true) {
    const { InMemoryEntitlementRepository } = await import(
      '../src/billing/entitlement-repository.js'
    );
    const outbox = new InMemoryAckOutbox();
    const scheduler = new Scheduler();
    let now = 1_800_000_000_000;
    const google: StoreVerifier = {
      get configured() {
        return true;
      },
      verify: async () => ({
        ...billingResult('active', 'subscription_active'),
        acknowledgementPending: true,
      }),
      acknowledge: async () => false,
    };
    const app = await testApp(authedConfig(), undefined, {
      billing: { google },
      entitlementRepository: new InMemoryEntitlementRepository(),
      billingAck: {
        outbox,
        scheduler,
        verifyTask: async () => taskVerified,
        now: () => now,
      },
    });
    const verify = (token = 'play-token') =>
      app.inject({
        method: 'POST',
        url: '/v1/billing/verify',
        headers: { authorization: `Bearer ${bearer}`, 'content-type': 'application/json' },
        payload: { platform: 'android', productId: MONTHLY, purchaseToken: token },
      });
    const sweep = async () =>
      app.inject({ method: 'POST', url: '/internal/billing/acknowledge-sweep', payload: {} });
    return {
      app,
      outbox,
      scheduler,
      verify,
      sweep,
      advance: (ms: number) => {
        now += ms;
      },
      now: () => now,
    };
  }

  it('a task that cannot be created marks the entry; the answer is unchanged',
    async () => {
      const h = await harness();
      h.scheduler.fail = true;
      expect((await h.verify()).json()).toEqual({
        status: 'active',
        reason: 'subscription_active',
        acknowledgement: 'pending',
      });
      const [entry] = await h.outbox.all();
      expect(entry).toMatchObject({ status: 'pending', scheduleFailed: true });
      await h.app.close();
    });

  it('the sweep re-creates a task that never ran, and leaves due-later ones',
    async () => {
      const h = await harness();
      h.scheduler.fail = true;
      await h.verify('lost');
      h.scheduler.fail = false;
      await h.verify('on-time');
      h.advance(ACK_RETRY_DELAYS_MS[0]! + ACK_LOST_GRACE_MS + 1);
      // 'on-time' was scheduled; mark its task as just re-run in the future.
      const onTime = (await h.outbox.all()).find((e) => !e.scheduleFailed)!;
      await h.outbox.update(onTime.id, { nextAttemptAtMs: h.now() + 60_000 });
      const before = h.scheduler.scheduled.length;
      const res = await h.sweep();
      expect(res.statusCode).toBe(200);
      expect(res.json()).toMatchObject({ pending: 2, rescheduled: 1 });
      expect(h.scheduler.scheduled.length).toBe(before + 1);
      expect(h.scheduler.scheduled.at(-1)!.key).toBe(`s${h.now()}`);
      const lost = (await h.outbox.all()).find((e) => e.id !== onTime.id)!;
      expect(lost.scheduleFailed).toBeFalsy();
      await h.app.close();
    });

  it('the sweep reports entries pending past the overdue limit', async () => {
    const h = await harness();
    await h.verify();
    h.advance(ACK_OVERDUE_MS + 1);
    const body = (await h.sweep()).json();
    expect(body.overdue).toBe(1);
    await h.app.close();
  });

  it('the sweep endpoint refuses anyone but the billing task identity',
    async () => {
      const h = await harness(false);
      expect((await h.sweep()).statusCode).toBe(401);
      await h.app.close();
    });

  it('an abandoned entry stays visible as gave_up', async () => {
    const h = await harness();
    await h.verify();
    const [entry] = await h.outbox.all();
    for (let i = 0; i < ACK_RETRY_DELAYS_MS.length + 1; i++) {
      await h.app.inject({
        method: 'POST',
        url: '/internal/billing/acknowledge-retry',
        payload: { id: entry.id },
      });
    }
    const closed = (await h.outbox.get(entry.id)) as AckOutboxEntry;
    expect(closed).toMatchObject({ status: 'closed', lastReason: 'gave_up' });
    await h.app.close();
  });
});
