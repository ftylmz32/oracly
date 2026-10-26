/**
 * #44 — server-authoritative acknowledgement hand-off. The Android app no
 * longer acknowledges before the backend has verified and bound a
 * purchase, so the verify answer tells it, for an active Android purchase
 * only, whether Play now holds the purchase acknowledged:
 *
 * - `acknowledged`: Play said so (already acknowledged, or our
 *   acknowledge call succeeded). The app must not acknowledge again.
 * - `pending`: our acknowledge failed and the purchase sits in the durable
 *   outbox. The app may acknowledge it itself, now that it is verified and
 *   bound; the outbox retry then finds it acknowledged and closes.
 *
 * Nothing else ever carries the field: no ack hint for a purchase that is
 * not verified, not bound to the caller, or not Android. Old clients
 * ignore it; the request shape is unchanged (the schema strips unknown
 * request fields, so nothing the client sends can claim an ack).
 */
import { describe, expect, it } from 'vitest';
import { createGooglePlayVerifier } from '../src/billing/google-play.js';
import {
  InMemoryAckOutbox,
  type AckRetryScheduler,
} from '../src/billing/ack-outbox.js';
import { billingResult, type StoreVerifier } from '../src/billing/types.js';
import { signHs256, testApp, testConfig } from './helpers.js';

const MONTHLY = 'app.oracly.premium.monthly';
const LIFETIME = 'app.oracly.premium.lifetime';

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });

describe('the Google verifier reports Play\'s acknowledgement state both ways',
  () => {
    const future = new Date(Date.now() + 86_400_000).toISOString();
    const verifierReturning = (body: unknown) =>
      createGooglePlayVerifier({
        packageName: 'app.oracly',
        credentials: { client_email: 'x', private_key: 'y' },
        getAccessToken: async () => 'access',
        fetchImpl: (async () => json(body)) as typeof fetch,
      });

    it('an acknowledged subscription is reported as not pending', async () => {
      const result = await verifierReturning({
        subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
        acknowledgementState: 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED',
        lineItems: [{ productId: MONTHLY, expiryTime: future }],
      }).verify({ platform: 'android', productId: MONTHLY, purchaseToken: 't' });
      expect(result.acknowledgementPending).toBe(false);
    });

    it('an acknowledged one-time product is reported as not pending', async () => {
      const result = await verifierReturning({
        purchaseState: 0,
        acknowledgementState: 1,
      }).verify({ platform: 'android', productId: LIFETIME, purchaseToken: 't' });
      expect(result.status).toBe('active');
      expect(result.acknowledgementPending).toBe(false);
    });
  });

describe('the verify answer hands the acknowledgement state to the app', () => {
  const secret = 'billing-test-secret';
  const config = () =>
    testConfig({
      AI_DEV_AUTH_BYPASS: 'false',
      AI_AUTH_REQUIRED: 'true',
      AI_JWT_SECRET: secret,
      AI_JWT_ISSUER: 'https://issuer.example',
      AI_JWT_AUDIENCE: 'oracly-ai',
      FIREBASE_PROJECT_ID: '',
      AI_JWKS_URL: '',
    });
  const bearer = (sub: string) =>
    signHs256(secret, { sub, iss: 'https://issuer.example', aud: 'oracly-ai' });

  /** Play, as far as one token is concerned. */
  class Play implements StoreVerifier {
    status: 'active' | 'pending' | 'inactive' = 'active';
    acknowledged = false;
    ackWorks = true;
    ackCalls = 0;
    get configured() {
      return true;
    }
    async verify() {
      if (this.status !== 'active') {
        return billingResult(this.status, `subscription_${this.status}`);
      }
      return {
        ...billingResult('active', 'subscription_active'),
        acknowledgementPending: !this.acknowledged,
      };
    }
    async acknowledge() {
      this.ackCalls++;
      if (!this.ackWorks) return false;
      this.acknowledged = true;
      return true;
    }
  }

  class Scheduler implements AckRetryScheduler {
    fail = false;
    async schedule() {
      if (this.fail) throw new Error('cloud tasks down');
    }
  }

  async function harness() {
    const { InMemoryEntitlementRepository } = await import(
      '../src/billing/entitlement-repository.js'
    );
    const play = new Play();
    const outbox = new InMemoryAckOutbox();
    const scheduler = new Scheduler();
    const app = await testApp(config(), undefined, {
      billing: { google: play },
      entitlementRepository: new InMemoryEntitlementRepository(),
      billingAck: { outbox, scheduler, verifyTask: async () => true },
    });
    const verify = async (
      sub = 'user-a',
      platform: 'android' | 'ios' = 'android',
      token = 'play-token',
    ) =>
      (
        await app.inject({
          method: 'POST',
          url: '/v1/billing/verify',
          headers: {
            authorization: `Bearer ${bearer(sub)}`,
            'content-type': 'application/json',
          },
          payload: { platform, productId: MONTHLY, purchaseToken: token },
        })
      ).json();
    return { app, play, outbox, scheduler, verify };
  }

  it('our acknowledge succeeded: the app is told it is acknowledged', async () => {
    const h = await harness();
    expect(await h.verify()).toEqual({
      status: 'active',
      reason: 'subscription_active',
      acknowledgement: 'acknowledged',
    });
    expect(h.play.ackCalls).toBe(1);
    expect(await h.outbox.all()).toHaveLength(0);
    await h.app.close();
  });

  it('already acknowledged at Play: told so, and never acknowledged twice',
    async () => {
      const h = await harness();
      await h.verify();
      const again = await h.verify();
      expect(again.acknowledgement).toBe('acknowledged');
      expect(h.play.ackCalls).toBe(1);
      await h.app.close();
    });

  it('our acknowledge failed: told pending, and the outbox keeps it', async () => {
    const h = await harness();
    h.play.ackWorks = false;
    expect((await h.verify()).acknowledgement).toBe('pending');
    expect(await h.outbox.all()).toHaveLength(1);
    await h.app.close();
  });

  it('acknowledge and the retry queue both failed: still told pending, the '
    + 'entry is kept and marked, and the purchase stays verified', async () => {
    const h = await harness();
    h.play.ackWorks = false;
    h.scheduler.fail = true;
    const answer = await h.verify();
    expect(answer).toMatchObject({ status: 'active', acknowledgement: 'pending' });
    const [entry] = await h.outbox.all();
    expect(entry).toMatchObject({ status: 'pending', scheduleFailed: true });
    await h.app.close();
  });

  for (const [label, status] of [
    ['still pending at Play', 'pending'],
    ['cancelled at Play', 'inactive'],
  ] as const) {
    it(`${label}: no acknowledge and no ack hint`, async () => {
      const h = await harness();
      h.play.status = status;
      const answer = await h.verify();
      expect(answer.acknowledgement).toBeUndefined();
      expect(h.play.ackCalls).toBe(0);
      await h.app.close();
    });
  }

  it('bound to another account: no acknowledge and no ack hint', async () => {
    const h = await harness();
    await h.verify('user-a');
    h.play.acknowledged = false;
    const callsBefore = h.play.ackCalls;
    const answer = await h.verify('user-b');
    expect(answer).toEqual({
      status: 'unverified',
      reason: 'purchase_bound_to_other_account',
    });
    expect(h.play.ackCalls).toBe(callsBefore);
    await h.app.close();
  });

  it('iOS answers never carry an ack hint', async () => {
    const h = await harness();
    const ios: StoreVerifier = {
      get configured() {
        return true;
      },
      verify: async () => billingResult('active', 'subscription_active'),
    };
    const { InMemoryEntitlementRepository } = await import(
      '../src/billing/entitlement-repository.js'
    );
    const app = await testApp(config(), undefined, {
      billing: { google: h.play, apple: ios },
      entitlementRepository: new InMemoryEntitlementRepository(),
    });
    const answer = (
      await app.inject({
        method: 'POST',
        url: '/v1/billing/verify',
        headers: {
          authorization: `Bearer ${bearer('user-a')}`,
          'content-type': 'application/json',
        },
        payload: { platform: 'ios', productId: MONTHLY, purchaseToken: 'apple' },
      })
    ).json();
    expect(answer.status).toBe('active');
    expect(answer.acknowledgement).toBeUndefined();
    await app.close();
    await h.app.close();
  });

  it('the request shape is unchanged: an extra field is stripped, never trusted',
    async () => {
    const h = await harness();
    const res = await h.app.inject({
      method: 'POST',
      url: '/v1/billing/verify',
      headers: {
        authorization: `Bearer ${bearer('user-a')}`,
        'content-type': 'application/json',
      },
      payload: {
        platform: 'android',
        productId: MONTHLY,
        purchaseToken: 'play-token',
        acknowledgement: 'acknowledged',
      },
    });
    // The client cannot claim an acknowledgement: the server still asks
    // Play and acknowledges itself.
    expect(res.json()).toMatchObject({ status: 'active', acknowledgement: 'acknowledged' });
    expect(h.play.ackCalls).toBe(1);
    await h.app.close();
  });
});
