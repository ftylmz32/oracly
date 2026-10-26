/**
 * Gate B2 real-device observation — two `billing_acknowledge` events for the
 * one license-test purchase (15:24:41). This reproduces the cause with a
 * fake Play: verify requests that read Play's state before either has
 * acknowledged both see it unacknowledged, and the route acknowledges in
 * each (there is no per-token single-flight). Measures current behavior;
 * no source is changed.
 */
import { describe, expect, it } from 'vitest';
import { InMemoryAckOutbox } from '../src/billing/ack-outbox.js';
import { billingResult, type StoreVerifier } from '../src/billing/types.js';
import { signHs256, testApp, testConfig } from './helpers.js';

const MONTHLY = 'app.oracly.premium.yearly';
const SECRET = 'billing-test-secret';

async function harness(options: { overlapReads: boolean }) {
  const { InMemoryEntitlementRepository } = await import(
    '../src/billing/entitlement-repository.js'
  );
  let acknowledged = false;
  let ackCalls = 0;
  let reads = 0;
  let release: () => void = () => {};
  const bothRead = new Promise<void>((resolve) => (release = resolve));
  const play: StoreVerifier = {
    get configured() {
      return true;
    },
    async verify() {
      const pending = !acknowledged; // Play's state as this read sees it
      reads += 1;
      if (options.overlapReads) {
        if (reads === 2) release();
        await bothRead;
      }
      return { ...billingResult('active', 'subscription_active'), acknowledgementPending: pending };
    },
    async acknowledge() {
      ackCalls += 1;
      acknowledged = true;
      return true;
    },
  };
  const app = await testApp(
    testConfig({
      AI_DEV_AUTH_BYPASS: 'false',
      AI_AUTH_REQUIRED: 'true',
      AI_JWT_SECRET: SECRET,
      AI_JWT_ISSUER: 'https://issuer.example',
      AI_JWT_AUDIENCE: 'oracly-ai',
      FIREBASE_PROJECT_ID: '',
      AI_JWKS_URL: '',
    }),
    undefined,
    {
      billing: { google: play },
      entitlementRepository: new InMemoryEntitlementRepository(),
      billingAck: { outbox: new InMemoryAckOutbox(), scheduler: { schedule: async () => {} }, verifyTask: async () => true },
    },
  );
  const bearer = signHs256(SECRET, { sub: 'user-a', iss: 'https://issuer.example', aud: 'oracly-ai' });
  const verify = async () =>
    (
      await app.inject({
        method: 'POST',
        url: '/v1/billing/verify',
        headers: { authorization: `Bearer ${bearer}`, 'content-type': 'application/json' },
        payload: { platform: 'android', productId: MONTHLY, purchaseToken: 'play-token' },
      })
    ).json();
  return { app, verify, ackCalls: () => ackCalls };
}

describe('concurrent verifies of one purchase and Play acknowledgement', () => {
  it('MEASURED: two verifies that read Play before either acknowledges both '
    + 'acknowledge (2 Play calls); both answer active + acknowledged', async () => {
    const h = await harness({ overlapReads: true });
    const [a, b] = await Promise.all([h.verify(), h.verify()]);
    expect(h.ackCalls()).toBe(2);
    expect(a).toMatchObject({ status: 'active', acknowledgement: 'acknowledged' });
    expect(b).toMatchObject({ status: 'active', acknowledgement: 'acknowledged' });
    await h.app.close();
  });

  it('sequential verifies acknowledge exactly once (the later read sees it '
    + 'acknowledged)', async () => {
    const h = await harness({ overlapReads: false });
    await h.verify();
    await h.verify();
    await h.verify();
    expect(h.ackCalls()).toBe(1);
    await h.app.close();
  });
});
