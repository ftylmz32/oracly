/**
 * #44 Gate B2 — the backend's acknowledgement-failure enqueue path, end to
 * end through the route and the real Cloud Tasks scheduler, with only Play
 * and the Cloud Tasks HTTP transport faked (no network, no real queue):
 *
 * verified at Play → bound to the caller → our acknowledge fails → one
 * durable outbox entry → one Cloud Tasks create on the billing queue, as
 * the billing identity, targeting the retry route.
 *
 * A purchase that is not verified and bound (Play pending, cancelled,
 * unknown, store error, another account's) produces no binding, no outbox
 * entry and no task. A task the queue already holds (409) counts as
 * scheduled; any other queue failure marks the entry and logs an error.
 */
import { describe, expect, it, vi } from 'vitest';
import {
  CloudTasksAckRetryScheduler,
  InMemoryAckOutbox,
  ackOutboxId,
} from '../src/billing/ack-outbox.js';
import { purchaseBindingKey } from '../src/billing/entitlement-repository.js';
import { premiumOwnerTag } from '../src/billing/purchase-owner-tag.js';
import {
  billingResult,
  type BillingVerifyResult,
  type StoreVerifier,
} from '../src/billing/types.js';
import { signHs256, testApp, testConfig } from './helpers.js';

const MONTHLY = 'app.oracly.premium.monthly';
const SECRET = 'billing-test-secret';
const QA = 'https://oracly-api-play-qa-x.a.run.app';
const BILLING_SA = 'oracly-billing-ack-qa@oracly-7f613.iam.gserviceaccount.com';

/** The app: HS256 test auth (a Firebase project id would switch auth mode). */
const appConfig = () =>
  testConfig({
    AI_DEV_AUTH_BYPASS: 'false',
    AI_AUTH_REQUIRED: 'true',
    AI_JWT_SECRET: SECRET,
    AI_JWT_ISSUER: 'https://issuer.example',
    AI_JWT_AUDIENCE: 'oracly-ai',
    AI_JWKS_URL: '',
    FIREBASE_PROJECT_ID: '',
  });
/** The scheduler: the QA queue settings as deployed. */
const queueConfig = () =>
  testConfig({
    FIREBASE_PROJECT_ID: 'oracly-7f613',
    BILLING_ACK_QUEUE: 'oracly-billing-ack-qa',
    BILLING_ACK_LOCATION: 'europe-west1',
    BILLING_ACK_TARGET_URL: `${QA}/internal/billing/acknowledge-retry`,
    BILLING_ACK_AUDIENCE: QA,
    BILLING_ACK_SERVICE_ACCOUNT: BILLING_SA,
  });
const bearer = (sub: string) =>
  signHs256(SECRET, { sub, iss: 'https://issuer.example', aud: 'oracly-ai' });

/** The Cloud Tasks HTTP transport: records each create, answers as told. */
class FakeTasksTransport {
  requests: Array<{ url: string; data: any }> = [];
  answer: 'ok' | 409 | 500 = 'ok';
  async request(r: { url: string; data: any }) {
    this.requests.push(r);
    if (this.answer !== 'ok') {
      throw Object.assign(new Error(`cloud tasks ${this.answer}`), {
        response: { status: this.answer },
      });
    }
    return {};
  }
}

async function harness(verdict: BillingVerifyResult, ackWorks = false) {
  const { InMemoryEntitlementRepository } = await import(
    '../src/billing/entitlement-repository.js'
  );
  const transport = new FakeTasksTransport();
  const outbox = new InMemoryAckOutbox();
  const repository = new InMemoryEntitlementRepository();
  let ackCalls = 0;
  const play: StoreVerifier = {
    get configured() {
      return true;
    },
    verify: async () => verdict,
    acknowledge: async () => {
      ackCalls++;
      return ackWorks;
    },
  };
  const app = await testApp(appConfig(), undefined, {
    billing: { google: play },
    entitlementRepository: repository,
    billingAck: {
      outbox,
      scheduler: new CloudTasksAckRetryScheduler(queueConfig(), transport as never),
      verifyTask: async () => true,
    },
  });
  const errors = vi.spyOn(app.log, 'error');
  const verify = async (sub = 'user-a', token = 'play-token') =>
    (
      await app.inject({
        method: 'POST',
        url: '/v1/billing/verify',
        headers: {
          authorization: `Bearer ${bearer(sub)}`,
          'content-type': 'application/json',
        },
        payload: { platform: 'android', productId: MONTHLY, purchaseToken: token },
      })
    ).json() as Record<string, unknown>;
  const ownerOf = (token = 'play-token') =>
    repository.peekOwner(purchaseBindingKey('android', token));
  return { app, transport, outbox, verify, ownerOf, errors, acks: () => ackCalls };
}

const activeUnacked = (): BillingVerifyResult => ({
  ...billingResult('active', 'subscription_active'),
  acknowledgementPending: true,
});

describe('verified → bound → ack failed → one task on the billing queue', () => {
  it('the route makes exactly one Cloud Tasks create, on the billing queue, '
    + 'as the billing identity, targeting the retry route', async () => {
    const h = await harness(activeUnacked());
    const answer = await h.verify();
    expect(answer).toMatchObject({ status: 'active', acknowledgement: 'pending' });
    expect(h.acks()).toBe(1);
    // Bound to the caller before anything is queued.
    expect(await h.ownerOf()).not.toBeNull();
    const [entry] = await h.outbox.all();
    expect(entry).toMatchObject({
      id: ackOutboxId('android', 'play-token'),
      status: 'pending',
      attempts: 0,
    });
    expect(entry.scheduleFailed).toBeFalsy();
    expect(h.transport.requests).toHaveLength(1);
    const { url, data } = h.transport.requests[0];
    expect(url).toBe('https://cloudtasks.googleapis.com/v2/projects/oracly-7f613/'
      + 'locations/europe-west1/queues/oracly-billing-ack-qa/tasks');
    expect(data.task.name).toMatch(
      new RegExp(`/queues/oracly-billing-ack-qa/tasks/billing-ack-${entry.id}-0$`),
    );
    expect(data.task.httpRequest.url).toBe(`${QA}/internal/billing/acknowledge-retry`);
    expect(data.task.httpRequest.oidcToken).toEqual({
      serviceAccountEmail: BILLING_SA,
      audience: QA,
    });
    // The task carries the outbox id only: never the token or the owner.
    const body = Buffer.from(data.task.httpRequest.body, 'base64').toString();
    expect(JSON.parse(body)).toEqual({ id: entry.id });
    expect(JSON.stringify(data)).not.toContain('play-token');
    expect(JSON.stringify(data)).not.toContain('user-a');
    await h.app.close();
  });

  it('a repeated verify of the same token queues nothing more', async () => {
    const h = await harness(activeUnacked());
    await h.verify();
    await h.verify();
    expect(await h.outbox.all()).toHaveLength(1);
    expect(h.transport.requests).toHaveLength(1);
    await h.app.close();
  });

  it('a task the queue already holds (409) counts as scheduled', async () => {
    const h = await harness(activeUnacked());
    h.transport.answer = 409;
    await h.verify();
    const [entry] = await h.outbox.all();
    expect(entry.scheduleFailed).toBeFalsy();
    expect(h.errors).not.toHaveBeenCalledWith(
      expect.objectContaining({ errorCode: 'billing_ack_schedule_failed' }),
    );
    await h.app.close();
  });

  it('any other queue failure: entry kept and marked, error logged, the '
    + 'answer unchanged', async () => {
    const h = await harness(activeUnacked());
    h.transport.answer = 500;
    const answer = await h.verify();
    expect(answer).toMatchObject({ status: 'active', acknowledgement: 'pending' });
    const [entry] = await h.outbox.all();
    expect(entry).toMatchObject({ status: 'pending', scheduleFailed: true });
    expect(h.errors).toHaveBeenCalledWith(
      expect.objectContaining({ errorCode: 'billing_ack_schedule_failed' }),
    );
    // Logged without the token or the owner.
    expect(JSON.stringify(h.errors.mock.calls)).not.toContain('play-token');
    await h.app.close();
  });

  it('our acknowledge succeeded: nothing is queued', async () => {
    const h = await harness(activeUnacked(), true);
    await h.verify();
    expect(await h.outbox.all()).toHaveLength(0);
    expect(h.transport.requests).toHaveLength(0);
    await h.app.close();
  });
});

describe('nothing verified and bound → no binding, no entry, no task', () => {
  for (const [label, verdict] of [
    ['Play pending', billingResult('pending', 'subscription_pending')],
    ['cancelled', billingResult('inactive', 'subscription_state_pending_purchase_canceled')],
    ['unknown token', billingResult('inactive', 'not_found')],
    ['store error', billingResult('error', 'provider_unavailable')],
    ['unverified', billingResult('unverified', 'provider_not_configured')],
  ] as const) {
    it(label, async () => {
      const h = await harness({ ...verdict, acknowledgementPending: true });
      const answer = await h.verify();
      // A real answer from the route, not an auth refusal.
      expect(answer.status).toBe(verdict.status);
      expect(answer.acknowledgement).toBeUndefined();
      expect(await h.ownerOf()).toBeNull();
      expect(h.acks()).toBe(0);
      expect(await h.outbox.all()).toHaveLength(0);
      expect(h.transport.requests).toHaveLength(0);
      await h.app.close();
    });
  }

  it('another account\'s tagged purchase', async () => {
    const h = await harness({
      ...activeUnacked(),
      accountTag: premiumOwnerTag('user-b'),
    });
    const answer = await h.verify('user-a');
    expect(answer).toEqual({
      status: 'unverified',
      reason: 'purchase_bound_to_other_account',
    });
    expect(await h.ownerOf()).toBeNull();
    expect(h.acks()).toBe(0);
    expect(await h.outbox.all()).toHaveLength(0);
    expect(h.transport.requests).toHaveLength(0);
    await h.app.close();
  });
});
