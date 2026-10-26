/**
 * #44 — the backend acknowledges a Play purchase it has verified and bound
 * to its owner, so a paid purchase no longer depends on the app's next
 * store query to escape Play's automatic refund. Only an active (PURCHASED)
 * purchase, owned by the caller and still unacknowledged at Play, is
 * acknowledged. Pending, cancelled, unknown, fake and other-account
 * purchases never are. An acknowledgement failure never loses the binding
 * or changes the answer; the next verify retries it. Concurrent verifies
 * of one token never bind it twice.
 */
import { describe, expect, it } from 'vitest';
import { createGooglePlayVerifier } from '../src/billing/google-play.js';
import { premiumOwnerTag } from '../src/billing/purchase-owner-tag.js';
import type {
  BillingVerifyRequest,
  BillingVerifyResult,
  StoreVerifier,
} from '../src/billing/types.js';
import { billingResult } from '../src/billing/types.js';
import { signHs256, testApp, testConfig } from './helpers.js';

const MONTHLY = 'app.oracly.premium.monthly';
const LIFETIME = 'app.oracly.premium.lifetime';

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });

describe('the Google verifier reads and performs acknowledgement', () => {
  function verifierWith(
    handler: (url: string, init?: RequestInit) => Response | Promise<Response>,
  ) {
    const calls: Array<{ url: string; method: string }> = [];
    const verifier = createGooglePlayVerifier({
      packageName: 'app.oracly',
      credentials: { client_email: 'x', private_key: 'y' },
      getAccessToken: async () => 'access',
      fetchImpl: (async (url: string, init?: RequestInit) => {
        calls.push({ url: String(url), method: init?.method ?? 'GET' });
        return handler(String(url), init);
      }) as typeof fetch,
    });
    return { verifier, calls };
  }

  const future = new Date(Date.now() + 86_400_000).toISOString();

  it('an active, unacknowledged subscription is flagged for acknowledgement',
    async () => {
      const { verifier } = verifierWith(() =>
        json({
          subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
          acknowledgementState: 'ACKNOWLEDGEMENT_STATE_PENDING',
          lineItems: [{ productId: MONTHLY, expiryTime: future }],
        }),
      );
      const result = await verifier.verify({
        platform: 'android',
        productId: MONTHLY,
        purchaseToken: 'tok',
      });
      expect(result.status).toBe('active');
      expect(result.acknowledgementPending).toBe(true);
    });

  it('an already acknowledged subscription is not', async () => {
    const { verifier } = verifierWith(() =>
      json({
        subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
        acknowledgementState: 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED',
        lineItems: [{ productId: MONTHLY, expiryTime: future }],
      }),
    );
    const result = await verifier.verify({
      platform: 'android',
      productId: MONTHLY,
      purchaseToken: 'tok',
    });
    expect(result.acknowledgementPending).toBeFalsy();
  });

  it('a pending subscription is never flagged', async () => {
    const { verifier } = verifierWith(() =>
      json({
        subscriptionState: 'SUBSCRIPTION_STATE_PENDING',
        acknowledgementState: 'ACKNOWLEDGEMENT_STATE_PENDING',
        lineItems: [{ productId: MONTHLY }],
      }),
    );
    const result = await verifier.verify({
      platform: 'android',
      productId: MONTHLY,
      purchaseToken: 'tok',
    });
    expect(result.status).toBe('pending');
    expect(result.acknowledgementPending).toBeFalsy();
  });

  it('one-time product: acknowledgementState 0 means pending acknowledgement',
    async () => {
      const { verifier } = verifierWith(() =>
        json({ purchaseState: 0, acknowledgementState: 0 }),
      );
      const result = await verifier.verify({
        platform: 'android',
        productId: LIFETIME,
        purchaseToken: 'tok',
      });
      expect(result).toMatchObject({
        status: 'active',
        acknowledgementPending: true,
      });
    });

  it('acknowledges a subscription at its exact Play endpoint', async () => {
    const { verifier, calls } = verifierWith(() => new Response(null, { status: 204 }));
    const ok = await verifier.acknowledge!({
      platform: 'android',
      productId: MONTHLY,
      purchaseToken: 'tok/1',
    });
    expect(ok).toBe(true);
    expect(calls).toEqual([
      {
        url:
          'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/' +
          'app.oracly/purchases/subscriptions/app.oracly.premium.monthly/tokens/tok%2F1:acknowledge',
        method: 'POST',
      },
    ]);
  });

  it('acknowledges a one-time product at its exact Play endpoint', async () => {
    const { verifier, calls } = verifierWith(() => new Response(null, { status: 200 }));
    expect(
      await verifier.acknowledge!({
        platform: 'android',
        productId: LIFETIME,
        purchaseToken: 'tok',
      }),
    ).toBe(true);
    expect(calls[0].url).toContain(
      '/purchases/products/app.oracly.premium.lifetime/tokens/tok:acknowledge',
    );
  });

  it('a failed or unreachable acknowledgement reports false, never throws',
    async () => {
      const failing = verifierWith(() => json({ error: 'x' }, 500)).verifier;
      expect(
        await failing.acknowledge!({
          platform: 'android',
          productId: MONTHLY,
          purchaseToken: 'tok',
        }),
      ).toBe(false);
      const offline = verifierWith(() => {
        throw new TypeError('network down');
      }).verifier;
      expect(
        await offline.acknowledge!({
          platform: 'android',
          productId: MONTHLY,
          purchaseToken: 'tok',
        }),
      ).toBe(false);
    });
});

describe('the verify route acknowledges only verified, owned purchases', () => {
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

  function google(
    result: BillingVerifyResult,
    ackOk: () => boolean = () => true,
  ) {
    const acks: BillingVerifyRequest[] = [];
    const verifier: StoreVerifier = {
      get configured() {
        return true;
      },
      verify: async () => result,
      acknowledge: async (request) => {
        acks.push(request);
        return ackOk();
      },
    };
    return { verifier, acks };
  }

  async function appWith(verifier: StoreVerifier) {
    const { InMemoryEntitlementRepository } = await import(
      '../src/billing/entitlement-repository.js'
    );
    return testApp(authedConfig(), undefined, {
      billing: { google: verifier },
      entitlementRepository: new InMemoryEntitlementRepository(),
    });
  }

  async function verifyAs(
    app: Awaited<ReturnType<typeof testApp>>,
    sub: string,
    purchaseToken = 'play-token',
  ) {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/billing/verify',
      headers: {
        authorization: `Bearer ${bearer(sub)}`,
        'content-type': 'application/json',
      },
      payload: { platform: 'android', productId: MONTHLY, purchaseToken },
    });
    return res.json() as Record<string, unknown>;
  }

  const activeUnacked = (): BillingVerifyResult => ({
    ...billingResult('active', 'subscription_active'),
    acknowledgementPending: true,
  });

  it('a verified purchase bound to its owner is acknowledged once, and the '
    + 'answer carries no internal field', async () => {
    const { verifier, acks } = google(activeUnacked());
    const app = await appWith(verifier);
    const body = await verifyAs(app, 'user-a');
    expect(body).toEqual({
      status: 'active',
      reason: 'subscription_active',
      acknowledgement: 'acknowledged',
    });
    expect(acks).toHaveLength(1);
    expect(acks[0]).toMatchObject({ productId: MONTHLY, purchaseToken: 'play-token' });
    await app.close();
  });

  it('an already acknowledged purchase is not acknowledged again', async () => {
    const { verifier, acks } = google(billingResult('active', 'subscription_active'));
    const app = await appWith(verifier);
    await verifyAs(app, 'user-a');
    expect(acks).toHaveLength(0);
    await app.close();
  });

  for (const [label, result] of [
    ['pending', billingResult('pending', 'subscription_pending')],
    ['cancelled', billingResult('inactive', 'subscription_state_pending_purchase_canceled')],
    ['unknown token (fake)', billingResult('inactive', 'not_found')],
    ['store error', billingResult('error', 'provider_unavailable')],
  ] as const) {
    it(`a ${label} purchase is never acknowledged`, async () => {
      const { verifier, acks } = google({ ...result, acknowledgementPending: true });
      const app = await appWith(verifier);
      await verifyAs(app, 'user-a');
      expect(acks).toHaveLength(0);
      await app.close();
    });
  }

  it('another account\'s tagged purchase is never acknowledged by the caller',
    async () => {
      const { verifier, acks } = google({
        ...activeUnacked(),
        accountTag: premiumOwnerTag('user-b'),
      });
      const app = await appWith(verifier);
      expect((await verifyAs(app, 'user-a')).reason).toBe(
        'purchase_bound_to_other_account',
      );
      expect(acks).toHaveLength(0);
      await app.close();
    });

  it('a purchase bound to another account is never acknowledged by the caller',
    async () => {
      const { verifier, acks } = google(activeUnacked());
      const app = await appWith(verifier);
      await verifyAs(app, 'user-b');
      expect(acks).toHaveLength(1);
      expect((await verifyAs(app, 'user-a')).reason).toBe(
        'purchase_bound_to_other_account',
      );
      expect(acks).toHaveLength(1);
      await app.close();
    });

  it('an acknowledgement failure keeps the binding and the answer; the next '
    + 'verify retries it', async () => {
    let ok = false;
    const { verifier, acks } = google(activeUnacked(), () => ok);
    const app = await appWith(verifier);
    expect((await verifyAs(app, 'user-a')).status).toBe('active');
    expect(await verifyAs(app, 'user-b')).toMatchObject({
      reason: 'purchase_bound_to_other_account',
    });
    ok = true;
    expect((await verifyAs(app, 'user-a')).status).toBe('active');
    expect(acks).toHaveLength(2);
    await app.close();
  });

  it('an acknowledgement that throws never fails verification', async () => {
    const verifier: StoreVerifier = {
      get configured() {
        return true;
      },
      verify: async () => activeUnacked(),
      acknowledge: async () => {
        throw new Error('boom');
      },
    };
    const app = await appWith(verifier);
    expect((await verifyAs(app, 'user-a')).status).toBe('active');
    await app.close();
  });

  it('concurrent verifies of one token by two accounts bind it to one only',
    async () => {
      const { verifier } = google(activeUnacked());
      const app = await appWith(verifier);
      const [a, b] = await Promise.all([
        verifyAs(app, 'user-a', 'shared'),
        verifyAs(app, 'user-b', 'shared'),
      ]);
      const statuses = [a.status, b.status].sort();
      expect(statuses).toEqual(['active', 'unverified']);
      await app.close();
    });

  it('concurrent verifies by the owner never double-grant or fail', async () => {
    const { verifier, acks } = google(activeUnacked());
    const app = await appWith(verifier);
    const results = await Promise.all(
      Array.from({ length: 5 }, () => verifyAs(app, 'user-a', 'same')),
    );
    for (const r of results) expect(r.status).toBe('active');
    expect(acks.length).toBeGreaterThanOrEqual(1);
    await app.close();
  });
});
