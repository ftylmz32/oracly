/**
 * #44 — a Play acknowledgement that fails after a verified, owned purchase
 * is not left to the app reopening. It is written to a durable,
 * server-only outbox and a delayed task retries it. The retry re-reads
 * Play: it acknowledges only a purchase that is still PURCHASED, still
 * unacknowledged and still bound to the same account; a refunded or
 * cancelled purchase, or one bound elsewhere, is closed without
 * acknowledging. Failures back off and stop before Play's 3-day window.
 * Only a verified Cloud Task may drive it.
 */
import { describe, expect, it } from 'vitest';
import {
  ACK_RETRY_DELAYS_MS,
  InMemoryAckOutbox,
  type AckRetryScheduler,
} from '../src/billing/ack-outbox.js';
import type { BillingVerifyResult, StoreVerifier } from '../src/billing/types.js';
import { billingResult } from '../src/billing/types.js';
import { signHs256, testApp, testConfig } from './helpers.js';

const MONTHLY = 'app.oracly.premium.monthly';

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

const bearer = (sub: string) =>
  signHs256('billing-test-secret', {
    sub,
    iss: 'https://issuer.example',
    aud: 'oracly-ai',
  });

class RecordingScheduler implements AckRetryScheduler {
  readonly scheduled: Array<{ id: string; attempt: number; atMs: number }> = [];
  async schedule(input: { id: string; attempt: number; atMs: number }) {
    this.scheduled.push(input);
  }
}

type Play = {
  verdict: BillingVerifyResult;
  ackOk: boolean;
  acks: number;
};

function google(play: Play): StoreVerifier {
  return {
    get configured() {
      return true;
    },
    verify: async () => play.verdict,
    acknowledge: async () => {
      play.acks++;
      return play.ackOk;
    },
  };
}

const activeUnacked = (): BillingVerifyResult => ({
  ...billingResult('active', 'subscription_active'),
  acknowledgementPending: true,
});

async function harness(options: { taskVerified?: boolean } = {}) {
  const { InMemoryEntitlementRepository } = await import(
    '../src/billing/entitlement-repository.js'
  );
  const play: Play = { verdict: activeUnacked(), ackOk: false, acks: 0 };
  const outbox = new InMemoryAckOutbox();
  const scheduler = new RecordingScheduler();
  const repository = new InMemoryEntitlementRepository();
  let now = 1_800_000_000_000;
  const app = await testApp(authedConfig(), undefined, {
    billing: { google: google(play) },
    entitlementRepository: repository,
    billingAck: {
      outbox,
      scheduler,
      verifyTask: async () => options.taskVerified ?? true,
      now: () => now,
    },
  });
  const verifyAs = async (sub: string, token = 'play-token') =>
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
  const runTask = async (id: string) =>
    app.inject({
      method: 'POST',
      url: '/internal/billing/acknowledge-retry',
      headers: { 'content-type': 'application/json' },
      payload: { id },
    });
  return {
    app,
    play,
    outbox,
    scheduler,
    repository,
    verifyAs,
    runTask,
    advance: (ms: number) => {
      now += ms;
    },
    nowMs: () => now,
  };
}

describe('a failed acknowledgement is kept and retried server-side', () => {
  it('is written to the outbox and a delayed task is scheduled; the answer '
    + 'and binding are unchanged', async () => {
    const h = await harness();
    expect(await h.verifyAs('user-a')).toEqual({
      status: 'active',
      reason: 'subscription_active',
      acknowledgement: 'pending',
    });
    const entries = await h.outbox.all();
    expect(entries).toHaveLength(1);
    expect(entries[0]).toMatchObject({ status: 'pending', attempts: 0 });
    expect(h.scheduler.scheduled).toHaveLength(1);
    expect(h.scheduler.scheduled[0].atMs).toBe(h.nowMs() + ACK_RETRY_DELAYS_MS[0]);
    expect(h.scheduler.scheduled[0].id).toBe(entries[0].id);
    await h.app.close();
  });

  it('a successful acknowledgement leaves nothing pending', async () => {
    const h = await harness();
    h.play.ackOk = true;
    await h.verifyAs('user-a');
    expect(await h.outbox.all()).toHaveLength(0);
    expect(h.scheduler.scheduled).toHaveLength(0);
    await h.app.close();
  });

  it('a repeated failed verify keeps one outbox entry', async () => {
    const h = await harness();
    await h.verifyAs('user-a');
    await h.verifyAs('user-a');
    expect(await h.outbox.all()).toHaveLength(1);
    await h.app.close();
  });

  it('only a verified Cloud Task can drive a retry', async () => {
    const h = await harness({ taskVerified: false });
    await h.verifyAs('user-a');
    const [entry] = await h.outbox.all();
    const res = await h.runTask(entry.id);
    expect(res.statusCode).toBe(401);
    // Only the original inline attempt.
    expect(h.play.acks).toBe(1);
    await h.app.close();
  });

  it('the retry acknowledges a purchase still PURCHASED, unacknowledged and '
    + 'owned by the same account, once', async () => {
    const h = await harness();
    await h.verifyAs('user-a');
    const [entry] = await h.outbox.all();
    h.play.ackOk = true;
    expect((await h.runTask(entry.id)).statusCode).toBe(200);
    expect(h.play.acks).toBe(2);
    expect((await h.outbox.get(entry.id))?.status).toBe('done');
    await h.runTask(entry.id);
    // A finished entry is never acknowledged again.
    expect(h.play.acks).toBe(2);
    await h.app.close();
  });

  it('Play already acknowledged it: done without another call', async () => {
    const h = await harness();
    await h.verifyAs('user-a');
    const [entry] = await h.outbox.all();
    h.play.verdict = billingResult('active', 'subscription_active');
    await h.runTask(entry.id);
    expect(h.play.acks).toBe(1);
    expect((await h.outbox.get(entry.id))?.status).toBe('done');
    await h.app.close();
  });

  for (const [label, verdict] of [
    ['refunded / revoked', billingResult('inactive', 'not_found')],
    ['expired', billingResult('expired', 'subscription_expired')],
    ['cancelled pending', billingResult('inactive', 'subscription_state_pending_purchase_canceled')],
  ] as const) {
    it(`Play now says ${label}: closed, never acknowledged`, async () => {
      const h = await harness();
      await h.verifyAs('user-a');
      const [entry] = await h.outbox.all();
      h.play.verdict = verdict;
      h.play.ackOk = true;
      await h.runTask(entry.id);
      expect(h.play.acks).toBe(1);
      expect((await h.outbox.get(entry.id))?.status).toBe('closed');
      await h.app.close();
    });
  }

  it('the binding no longer names the same account: closed, never '
    + 'acknowledged', async () => {
    const h = await harness();
    await h.verifyAs('user-a');
    const [entry] = await h.outbox.all();
    await h.outbox.rewriteOwnerForTest(entry.id, 'someone-else');
    h.play.ackOk = true;
    await h.runTask(entry.id);
    expect(h.play.acks).toBe(1);
    expect((await h.outbox.get(entry.id))?.status).toBe('closed');
    await h.app.close();
  });

  it('a store error or failed acknowledgement backs off and reschedules',
    async () => {
      const h = await harness();
      await h.verifyAs('user-a');
      const [entry] = await h.outbox.all();
      h.play.verdict = billingResult('error', 'provider_unavailable');
      await h.runTask(entry.id);
      h.play.verdict = activeUnacked();
      await h.runTask(entry.id);
      const after = await h.outbox.get(entry.id);
      expect(after).toMatchObject({ status: 'pending', attempts: 2 });
      expect(h.scheduler.scheduled.map((s) => s.attempt)).toEqual([0, 1, 2]);
      expect(h.scheduler.scheduled[2].atMs).toBe(h.nowMs() + ACK_RETRY_DELAYS_MS[2]);
      await h.app.close();
    });

  it('gives up before Play\'s 3-day window and never loops', async () => {
    const h = await harness();
    await h.verifyAs('user-a');
    const [entry] = await h.outbox.all();
    for (let i = 0; i < ACK_RETRY_DELAYS_MS.length + 2; i++) {
      await h.runTask(entry.id);
    }
    expect((await h.outbox.get(entry.id))?.status).toBe('closed');
    expect((await h.outbox.get(entry.id))?.lastReason).toBe('gave_up');
    const total = ACK_RETRY_DELAYS_MS.reduce((a, b) => a + b, 0);
    expect(total).toBeLessThan(3 * 24 * 3_600_000);
    await h.app.close();
  });

  it('the outbox never reaches a client response', async () => {
    const h = await harness();
    const body = await h.verifyAs('user-a');
    // Only the ack hint is added; no outbox id, token or attempt data.
    expect(Object.keys(body).sort()).toEqual(['acknowledgement', 'reason', 'status']);
    await h.app.close();
  });
});
