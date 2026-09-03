import { Environment, Status } from '@apple/app-store-server-library';
import { describe, expect, it } from 'vitest';
import type { StoreVerifier } from '../src/billing/types.js';
import { billingResult } from '../src/billing/types.js';
import { testApp, testConfig, signHs256 } from './helpers.js';

const MONTHLY = 'app.oracly.premium.monthly';
const YEARLY = 'app.oracly.premium.yearly';
const LIFETIME = 'app.oracly.premium.lifetime';

function billingTestConfig(overrides: Record<string, string> = {}) {
  return testConfig({
    AI_AUTH_REQUIRED: 'false',
    FIREBASE_PROJECT_ID: '',
    AI_JWKS_URL: '',
    AI_JWT_SECRET: '',
    ...overrides,
  });
}

function mockVerifier(
  impl: StoreVerifier['verify'],
  configured = true,
): StoreVerifier {
  return {
    get configured() {
      return configured;
    },
    verify: impl,
  };
}

async function post(
  app: Awaited<ReturnType<typeof testApp>>,
  payload: Record<string, unknown>,
) {
  return app.inject({
    method: 'POST',
    url: '/v1/billing/verify',
    payload,
  });
}

describe('billing verify request validation', () => {
  it('rejects missing platform', async () => {
    const app = await testApp(billingTestConfig(), undefined, {
      billing: {
        google: mockVerifier(async () => billingResult('active')),
      },
    });
    const res = await post(app, {
      productId: MONTHLY,
      purchaseToken: 'token',
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().status).toBe('unverified');
    expect(res.json().reason).toBe('invalid_request');
    expect(JSON.stringify(res.json()).includes('"active"')).toBe(false);
    await app.close();
  });

  it('rejects invalid platform', async () => {
    const app = await testApp(billingTestConfig());
    const res = await post(app, {
      platform: 'web',
      productId: MONTHLY,
      purchaseToken: 'token',
    });
    expect(res.json()).toEqual({
      status: 'unverified',
      reason: 'invalid_request',
    });
    await app.close();
  });

  it('rejects missing productId', async () => {
    const app = await testApp(billingTestConfig());
    const res = await post(app, {
      platform: 'android',
      purchaseToken: 'token',
    });
    expect(res.json().reason).toBe('invalid_request');
    await app.close();
  });

  it('rejects missing and empty purchaseToken', async () => {
    const app = await testApp(billingTestConfig());
    const missing = await post(app, {
      platform: 'android',
      productId: MONTHLY,
    });
    expect(missing.json().reason).toBe('invalid_request');
    const empty = await post(app, {
      platform: 'android',
      productId: MONTHLY,
      purchaseToken: '',
    });
    expect(empty.json().reason).toBe('invalid_request');
    await app.close();
  });

  it('unknown product never active', async () => {
    const app = await testApp(billingTestConfig(), undefined, {
      billing: {
        google: mockVerifier(async () => billingResult('active', 'should_not_run')),
      },
    });
    const res = await post(app, {
      platform: 'android',
      productId: 'app.oracly.premium.unknown',
      purchaseToken: 'token',
    });
    expect(res.json().status).toBe('unverified');
    expect(res.json().reason).toBe('unknown_product');
    expect(JSON.stringify(res.json()).includes('"active"')).toBe(false);
    await app.close();
  });

  it('unconfigured providers stay fail-closed', async () => {
    const app = await testApp(billingTestConfig());
    const res = await post(app, {
      platform: 'android',
      productId: YEARLY,
      purchaseToken: 'test-token',
    });
    expect(res.json()).toEqual({
      status: 'unverified',
      reason: 'provider_not_configured',
    });
    expect(JSON.stringify(res.json()).includes('"active"')).toBe(false);
    await app.close();
  });
});

describe('billing verify google', () => {
  it('maps subscription and product outcomes', async () => {
    const cases: Array<{
      name: string;
      productId: string;
      result: ReturnType<typeof billingResult>;
    }> = [
      {
        name: 'active monthly',
        productId: MONTHLY,
        result: billingResult('active', 'subscription_active'),
      },
      {
        name: 'active yearly',
        productId: YEARLY,
        result: billingResult('active', 'subscription_active'),
      },
      {
        name: 'canceled still entitled',
        productId: MONTHLY,
        result: billingResult('active', 'canceled_still_entitled'),
      },
      {
        name: 'grace',
        productId: MONTHLY,
        result: billingResult('active', 'grace_period'),
      },
      {
        name: 'pending',
        productId: MONTHLY,
        result: billingResult('pending', 'subscription_pending'),
      },
      {
        name: 'expired',
        productId: MONTHLY,
        result: billingResult('expired', 'subscription_expired'),
      },
      {
        name: 'revoked',
        productId: MONTHLY,
        result: billingResult('inactive', 'not_found'),
      },
      {
        name: 'mismatch',
        productId: MONTHLY,
        result: billingResult('unverified', 'product_mismatch'),
      },
      {
        name: 'lifetime',
        productId: LIFETIME,
        result: billingResult('active', 'product_purchased'),
      },
      {
        name: 'lifetime canceled',
        productId: LIFETIME,
        result: billingResult('inactive', 'product_canceled'),
      },
      {
        name: 'provider failure',
        productId: MONTHLY,
        result: billingResult('error', 'provider_unavailable'),
      },
    ];

    for (const c of cases) {
      const app = await testApp(billingTestConfig(), undefined, {
        billing: {
          google: mockVerifier(async () => c.result),
        },
      });
      const res = await post(app, {
        platform: 'android',
        productId: c.productId,
        purchaseToken: 'play-token',
        transactionId: 'spoof-order',
      });
      expect(res.json().status, c.name).toBe(c.result.status);
      expect(res.json().reason, c.name).toBe(c.result.reason);
      if (c.result.status !== 'active') {
        expect(JSON.stringify(res.json()).includes('"active"'), c.name).toBe(
          false,
        );
      }
      await app.close();
    }
  });

  it('client transactionId cannot force active', async () => {
    const app = await testApp(billingTestConfig(), undefined, {
      billing: {
        google: mockVerifier(async (req) => {
          // Ignore client transactionId — store decides.
          if (req.transactionId === 'force-active') {
            return billingResult('inactive', 'ignored_client_txn');
          }
          return billingResult('inactive', 'no_entitlement');
        }),
      },
    });
    const res = await post(app, {
      platform: 'android',
      productId: MONTHLY,
      purchaseToken: 'token',
      transactionId: 'force-active',
    });
    expect(res.json().status).not.toBe('active');
    await app.close();
  });
});

describe('billing verify apple', () => {
  it('maps SK2 / status outcomes', async () => {
    const cases = [
      billingResult('active', 'subscription_active'),
      billingResult('active', 'grace_period'),
      billingResult('expired', 'subscription_expired'),
      billingResult('inactive', 'revoked'),
      billingResult('active', 'lifetime_owned'),
      billingResult('unverified', 'jws_invalid'),
      billingResult('unverified', 'bundle_mismatch'),
      billingResult('unverified', 'product_mismatch'),
      billingResult('error', 'provider_unavailable'),
      billingResult('unverified', 'receipt_no_transaction_id'),
    ];
    for (const result of cases) {
      const app = await testApp(billingTestConfig(), undefined, {
        billing: {
          apple: mockVerifier(async () => result),
        },
      });
      const res = await post(app, {
        platform: 'ios',
        productId: result.reason === 'lifetime_owned' ? LIFETIME : MONTHLY,
        purchaseToken: 'a.b.c',
      });
      expect(res.json().status).toBe(result.status);
      if (result.status !== 'active') {
        expect(JSON.stringify(res.json()).includes('"active"')).toBe(false);
      }
      await app.close();
    }
  });

  it('uses App Store status not stale client product override', async () => {
    const app = await testApp(billingTestConfig(), undefined, {
      billing: {
        apple: mockVerifier(async (req) => {
          if (req.productId !== MONTHLY) {
            return billingResult('unverified', 'product_mismatch');
          }
          return billingResult('active', 'subscription_active');
        }),
      },
    });
    const mismatch = await post(app, {
      platform: 'ios',
      productId: YEARLY,
      purchaseToken: 'a.b.c',
    });
    // Still known product — mock returns mismatch for non-monthly
    expect(mismatch.json().status).toBe('unverified');
    await app.close();
  });

  it('apple unit: renewed status beats stale expiry via seam', async () => {
    const { createAppleStoreVerifier } = await import(
      '../src/billing/apple-store.js'
    );
    const future = Date.now() + 86_400_000;
    const past = Date.now() - 86_400_000;
    const verifier = createAppleStoreVerifier({
      bundleId: 'app.oracly',
      appAppleId: 1,
      issuerId: 'issuer',
      keyId: 'key',
      privateKey: 'pem',
      rootCertificates: [Buffer.from('cert')],
      preferEnvironment: 'Production',
      verifyJws: async () => ({
        bundleId: 'app.oracly',
        productId: MONTHLY,
        originalTransactionId: 'orig-1',
        transactionId: 'txn-old',
        expiresDate: past,
      }),
      getSubscriptionStatuses: async () => ({
        statuses: [
          {
            status: Status.ACTIVE,
            productId: MONTHLY,
            expiresDate: future,
          },
        ],
      }),
    });
    const result = await verifier.verify({
      platform: 'ios',
      productId: MONTHLY,
      purchaseToken: 'header.payload.sig',
    });
    expect(result.status).toBe('active');
    expect(result.reason).toBe('subscription_active');
  });

  it('apple unit: invalid JWS never active', async () => {
    const { createAppleStoreVerifier } = await import(
      '../src/billing/apple-store.js'
    );
    const verifier = createAppleStoreVerifier({
      bundleId: 'app.oracly',
      appAppleId: 1,
      issuerId: 'issuer',
      keyId: 'key',
      privateKey: 'pem',
      rootCertificates: [Buffer.from('cert')],
      preferEnvironment: 'Production',
      verifyJws: async () => {
        throw new Error('VERIFICATION_FAILURE');
      },
    });
    const result = await verifier.verify({
      platform: 'ios',
      productId: MONTHLY,
      purchaseToken: 'header.payload.sig',
    });
    expect(result.status).not.toBe('active');
  });

  it('apple unit: bundle mismatch never active', async () => {
    const { createAppleStoreVerifier } = await import(
      '../src/billing/apple-store.js'
    );
    const verifier = createAppleStoreVerifier({
      bundleId: 'app.oracly',
      appAppleId: 1,
      issuerId: 'issuer',
      keyId: 'key',
      privateKey: 'pem',
      rootCertificates: [Buffer.from('cert')],
      preferEnvironment: 'Production',
      verifyJws: async () => ({
        bundleId: 'com.other.app',
        productId: MONTHLY,
        originalTransactionId: 'orig-1',
      }),
    });
    const result = await verifier.verify({
      platform: 'ios',
      productId: MONTHLY,
      purchaseToken: 'header.payload.sig',
    });
    expect(result).toEqual({
      status: 'unverified',
      reason: 'bundle_mismatch',
    });
  });

  it('apple unit: SK1 receipt extracts txn then checks API', async () => {
    const { createAppleStoreVerifier } = await import(
      '../src/billing/apple-store.js'
    );
    const verifier = createAppleStoreVerifier({
      bundleId: 'app.oracly',
      appAppleId: 1,
      issuerId: 'issuer',
      keyId: 'key',
      privateKey: 'pem',
      rootCertificates: [Buffer.from('cert')],
      preferEnvironment: 'Sandbox',
      extractReceiptTransactionId: () => 'txn-from-receipt',
      getTransactionInfo: async () => ({
        bundleId: 'app.oracly',
        productId: LIFETIME,
        transactionId: 'txn-from-receipt',
      }),
    });
    const result = await verifier.verify({
      platform: 'ios',
      productId: LIFETIME,
      purchaseToken: 'MIISreceiptNotJws',
    });
    expect(result.status).toBe('active');
    expect(result.reason).toBe('lifetime_owned');
  });

  it('apple unit: malformed SK1 receipt never active', async () => {
    const { createAppleStoreVerifier } = await import(
      '../src/billing/apple-store.js'
    );
    const verifier = createAppleStoreVerifier({
      bundleId: 'app.oracly',
      appAppleId: 1,
      issuerId: 'issuer',
      keyId: 'key',
      privateKey: 'pem',
      rootCertificates: [Buffer.from('cert')],
      preferEnvironment: 'Production',
      extractReceiptTransactionId: () => null,
    });
    const result = await verifier.verify({
      platform: 'ios',
      productId: MONTHLY,
      purchaseToken: 'not-a-jws-or-receipt',
    });
    expect(result.status).not.toBe('active');
    expect(result.reason).toBe('receipt_no_transaction_id');
  });

  it('apple unit: sandbox fallback after production not found', async () => {
    const { createAppleStoreVerifier } = await import(
      '../src/billing/apple-store.js'
    );
    const seen: Environment[] = [];
    const verifier = createAppleStoreVerifier({
      bundleId: 'app.oracly',
      appAppleId: 1,
      issuerId: 'issuer',
      keyId: 'key',
      privateKey: 'pem',
      rootCertificates: [Buffer.from('cert')],
      preferEnvironment: 'Production',
      extractReceiptTransactionId: () => 'txn-1',
      getTransactionInfo: async (_id, environment) => {
        seen.push(environment);
        if (environment === Environment.PRODUCTION) {
          const err = Object.assign(new Error('TransactionIdNotFound'), {
            apiError: 4040010,
          });
          throw err;
        }
        return {
          bundleId: 'app.oracly',
          productId: LIFETIME,
          transactionId: 'txn-1',
        };
      },
    });
    const result = await verifier.verify({
      platform: 'ios',
      productId: LIFETIME,
      purchaseToken: 'MIISreceipt',
    });
    expect(seen).toEqual([Environment.PRODUCTION, Environment.SANDBOX]);
    expect(result.status).toBe('active');
  });
});

describe('billing verify google unit mapping', () => {
  it('subscriptionv2 responses map to statuses', async () => {
    const { createGooglePlayVerifier } = await import(
      '../src/billing/google-play.js'
    );
    const future = new Date(Date.now() + 86_400_000).toISOString();
    const past = new Date(Date.now() - 86_400_000).toISOString();

    async function run(
      body: unknown,
      productId = MONTHLY,
    ): Promise<string> {
      const verifier = createGooglePlayVerifier({
        packageName: 'app.oracly',
        credentials: { client_email: 'x', private_key: 'y' } as never,
        getAccessToken: async () => 'access',
        fetchImpl: async () =>
          new Response(JSON.stringify(body), {
            status: 200,
            headers: { 'content-type': 'application/json' },
          }),
      });
      const result = await verifier.verify({
        platform: 'android',
        productId,
        purchaseToken: 'tok',
      });
      return `${result.status}:${result.reason ?? ''}`;
    }

    expect(
      await run({
        subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
        lineItems: [{ productId: MONTHLY, expiryTime: future }],
      }),
    ).toBe('active:subscription_active');

    expect(
      await run({
        subscriptionState: 'SUBSCRIPTION_STATE_CANCELED',
        lineItems: [{ productId: MONTHLY, expiryTime: future }],
      }),
    ).toBe('active:canceled_still_entitled');

    expect(
      await run({
        subscriptionState: 'SUBSCRIPTION_STATE_CANCELED',
        lineItems: [{ productId: MONTHLY, expiryTime: past }],
      }),
    ).toBe('expired:canceled_expired');

    expect(
      await run({
        subscriptionState: 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
        lineItems: [{ productId: MONTHLY, expiryTime: future }],
      }),
    ).toBe('active:grace_period');

    expect(
      await run({
        subscriptionState: 'SUBSCRIPTION_STATE_PENDING',
        lineItems: [{ productId: MONTHLY }],
      }),
    ).toBe('pending:subscription_pending');

    expect(
      await run({
        subscriptionState: 'SUBSCRIPTION_STATE_EXPIRED',
        lineItems: [{ productId: MONTHLY }],
      }),
    ).toBe('expired:subscription_expired');

    expect(
      await run({
        subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
        lineItems: [{ productId: YEARLY, expiryTime: future }],
      }),
    ).toBe('unverified:product_mismatch');

    const lifetime = createGooglePlayVerifier({
      packageName: 'app.oracly',
      credentials: { client_email: 'x', private_key: 'y' } as never,
      getAccessToken: async () => 'access',
      fetchImpl: async () =>
        new Response(JSON.stringify({ purchaseState: 0 }), {
          status: 200,
          headers: { 'content-type': 'application/json' },
        }),
    });
    expect(
      (
        await lifetime.verify({
          platform: 'android',
          productId: LIFETIME,
          purchaseToken: 'tok',
        })
      ).status,
    ).toBe('active');

    const canceledLife = createGooglePlayVerifier({
      packageName: 'app.oracly',
      credentials: { client_email: 'x', private_key: 'y' } as never,
      getAccessToken: async () => 'access',
      fetchImpl: async () =>
        new Response(JSON.stringify({ purchaseState: 1 }), {
          status: 200,
          headers: { 'content-type': 'application/json' },
        }),
    });
    expect(
      (
        await canceledLife.verify({
          platform: 'android',
          productId: LIFETIME,
          purchaseToken: 'tok',
        })
      ).status,
    ).not.toBe('active');

    const fail = createGooglePlayVerifier({
      packageName: 'app.oracly',
      credentials: { client_email: 'x', private_key: 'y' } as never,
      getAccessToken: async () => {
        throw new Error('network');
      },
    });
    expect(
      (
        await fail.verify({
          platform: 'android',
          productId: MONTHLY,
          purchaseToken: 'tok',
        })
      ).status,
    ).toBe('error');
  });
});

describe('billing security', () => {
  it('no provider proof never active', async () => {
    const app = await testApp(billingTestConfig());
    for (const platform of ['android', 'ios'] as const) {
      const res = await post(app, {
        platform,
        productId: MONTHLY,
        purchaseToken: 'anything',
        transactionId: 'also-anything',
      });
      expect(res.json().status).not.toBe('active');
    }
    await app.close();
  });
});


describe('P0 billing regressions', () => {
  const future = new Date(Date.now() + 86_400_000).toISOString();
  const past = new Date(Date.now() - 86_400_000).toISOString();
  const futureMs = Date.now() + 86_400_000;
  const pastMs = Date.now() - 86_400_000;
  const laterMs = Date.now() + 172_800_000;

  async function googleBody(body: unknown, productId = MONTHLY) {
    const { createGooglePlayVerifier } = await import(
      '../src/billing/google-play.js'
    );
    const verifier = createGooglePlayVerifier({
      packageName: 'app.oracly',
      credentials: { client_email: 'x', private_key: 'y' } as never,
      getAccessToken: async () => 'access',
      fetchImpl: async () =>
        new Response(JSON.stringify(body), {
          status: 200,
          headers: { 'content-type': 'application/json' },
        }),
    });
    return verifier.verify({
      platform: 'android',
      productId,
      purchaseToken: 'tok',
    });
  }

  function appleCfg(
    overrides: Partial<
      import('../src/billing/apple-store.js').AppleStoreConfig
    > = {},
  ) {
    return {
      bundleId: 'app.oracly',
      appAppleId: 1,
      issuerId: 'issuer',
      keyId: 'key',
      privateKey: 'pem',
      rootCertificates: [Buffer.from('cert')],
      preferEnvironment: 'Production' as const,
      ...overrides,
    };
  }

  it('P0-1 ACTIVE missing expiry is not active', async () => {
    const result = await googleBody({
      subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
      lineItems: [{ productId: MONTHLY }],
    });
    expect(result.status).toBe('unverified');
    expect(result.status).not.toBe('active');
  });

  it('P0-1 ACTIVE malformed expiry is not active', async () => {
    const result = await googleBody({
      subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
      lineItems: [{ productId: MONTHLY, expiryTime: 'not-a-date' }],
    });
    expect(result.status).not.toBe('active');
    expect(result.status).toBe('unverified');
  });

  it('P0-1 CANCELED missing expiry is not active', async () => {
    const result = await googleBody({
      subscriptionState: 'SUBSCRIPTION_STATE_CANCELED',
      lineItems: [{ productId: MONTHLY }],
    });
    expect(result.status).not.toBe('active');
    expect(result.status).toBe('unverified');
  });

  it('P0-1 CANCELED future expiry is active', async () => {
    const result = await googleBody({
      subscriptionState: 'SUBSCRIPTION_STATE_CANCELED',
      lineItems: [{ productId: MONTHLY, expiryTime: future }],
    });
    expect(result.status).toBe('active');
  });

  it('P0-1 CANCELED past expiry is expired', async () => {
    const result = await googleBody({
      subscriptionState: 'SUBSCRIPTION_STATE_CANCELED',
      lineItems: [{ productId: MONTHLY, expiryTime: past }],
    });
    expect(result.status).toBe('expired');
  });

  it('P0-2 expired first matching item does not deny valid second', async () => {
    const result = await googleBody({
      subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
      lineItems: [
        { productId: MONTHLY, expiryTime: past },
        { productId: MONTHLY, expiryTime: future },
      ],
    });
    expect(result.status).toBe('active');
  });

  it('P0-2 prefers later future expiry among matches', async () => {
    const older = new Date(Date.now() + 86_400_000).toISOString();
    const newer = new Date(Date.now() + 172_800_000).toISOString();
    const result = await googleBody({
      subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
      lineItems: [
        { productId: MONTHLY, expiryTime: older },
        { productId: MONTHLY, expiryTime: newer },
      ],
    });
    expect(result.status).toBe('active');
  });

  it('P0-2 unrelated future product cannot activate requested expired SKU', async () => {
    const result = await googleBody({
      subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
      lineItems: [
        { productId: YEARLY, expiryTime: future },
        { productId: MONTHLY, expiryTime: past },
      ],
    });
    expect(result.status).toBe('expired');
    expect(result.status).not.toBe('active');
  });

  it('P0-2 malformed match does not beat valid future match', async () => {
    const result = await googleBody({
      subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
      lineItems: [
        { productId: MONTHLY, expiryTime: 'bad' },
        { productId: MONTHLY, expiryTime: future },
      ],
    });
    expect(result.status).toBe('active');
  });

  it('P0-3 BILLING_RETRY missing expiresDate is not active', async () => {
    const { createAppleStoreVerifier } = await import(
      '../src/billing/apple-store.js'
    );
    const verifier = createAppleStoreVerifier(
      appleCfg({
        verifyJws: async () => ({
          bundleId: 'app.oracly',
          productId: MONTHLY,
          originalTransactionId: 'orig-1',
        }),
        getSubscriptionStatuses: async () => ({
          statuses: [{ status: Status.BILLING_RETRY, productId: MONTHLY }],
        }),
      }),
    );
    const result = await verifier.verify({
      platform: 'ios',
      productId: MONTHLY,
      purchaseToken: 'a.b.c',
    });
    expect(result.status).not.toBe('active');
  });

  it('P0-3 BILLING_RETRY malformed expiresDate is not active', async () => {
    const { createAppleStoreVerifier } = await import(
      '../src/billing/apple-store.js'
    );
    const verifier = createAppleStoreVerifier(
      appleCfg({
        verifyJws: async () => ({
          bundleId: 'app.oracly',
          productId: MONTHLY,
          originalTransactionId: 'orig-1',
        }),
        getSubscriptionStatuses: async () => ({
          statuses: [
            {
              status: Status.BILLING_RETRY,
              productId: MONTHLY,
              expiresDate: Number.NaN,
            },
          ],
        }),
      }),
    );
    const result = await verifier.verify({
      platform: 'ios',
      productId: MONTHLY,
      purchaseToken: 'a.b.c',
    });
    expect(result.status).not.toBe('active');
  });

  it('P0-3 BILLING_RETRY future expiresDate is active', async () => {
    const { createAppleStoreVerifier } = await import(
      '../src/billing/apple-store.js'
    );
    const verifier = createAppleStoreVerifier(
      appleCfg({
        verifyJws: async () => ({
          bundleId: 'app.oracly',
          productId: MONTHLY,
          originalTransactionId: 'orig-1',
        }),
        getSubscriptionStatuses: async () => ({
          statuses: [
            {
              status: Status.BILLING_RETRY,
              productId: MONTHLY,
              expiresDate: futureMs,
            },
          ],
        }),
      }),
    );
    const result = await verifier.verify({
      platform: 'ios',
      productId: MONTHLY,
      purchaseToken: 'a.b.c',
    });
    expect(result.status).toBe('active');
  });

  it('P0-3 BILLING_RETRY past expiresDate is not active', async () => {
    const { createAppleStoreVerifier } = await import(
      '../src/billing/apple-store.js'
    );
    const verifier = createAppleStoreVerifier(
      appleCfg({
        verifyJws: async () => ({
          bundleId: 'app.oracly',
          productId: MONTHLY,
          originalTransactionId: 'orig-1',
        }),
        getSubscriptionStatuses: async () => ({
          statuses: [
            {
              status: Status.BILLING_RETRY,
              productId: MONTHLY,
              expiresDate: pastMs,
            },
          ],
        }),
      }),
    );
    const result = await verifier.verify({
      platform: 'ios',
      productId: MONTHLY,
      purchaseToken: 'a.b.c',
    });
    expect(result.status).not.toBe('active');
    expect(result.status).toBe('pending');
  });

  it('P0-4 nested verification failure yields no active row', async () => {
    const { createAppleStoreVerifier } = await import(
      '../src/billing/apple-store.js'
    );
    // Seam returns empty = all nested JWS discarded after verify failure.
    const verifier = createAppleStoreVerifier(
      appleCfg({
        verifyJws: async () => ({
          bundleId: 'app.oracly',
          productId: MONTHLY,
          originalTransactionId: 'orig-1',
        }),
        getSubscriptionStatuses: async () => ({ statuses: [] }),
      }),
    );
    const result = await verifier.verify({
      platform: 'ios',
      productId: MONTHLY,
      purchaseToken: 'a.b.c',
    });
    expect(result.status).toBe('unverified');
    expect(result.status).not.toBe('active');
  });

  it('P0-4 second verified ACTIVE row wins after first discarded', async () => {
    const { createAppleStoreVerifier } = await import(
      '../src/billing/apple-store.js'
    );
    const verifier = createAppleStoreVerifier(
      appleCfg({
        verifyJws: async () => ({
          bundleId: 'app.oracly',
          productId: MONTHLY,
          originalTransactionId: 'orig-1',
        }),
        getSubscriptionStatuses: async () => ({
          statuses: [
            {
              status: Status.ACTIVE,
              productId: MONTHLY,
              expiresDate: futureMs,
            },
          ],
        }),
      }),
    );
    const result = await verifier.verify({
      platform: 'ios',
      productId: MONTHLY,
      purchaseToken: 'a.b.c',
    });
    expect(result.status).toBe('active');
  });

  it('P0-4 other-product ACTIVE does not unlock requested SKU', async () => {
    const { createAppleStoreVerifier } = await import(
      '../src/billing/apple-store.js'
    );
    const verifier = createAppleStoreVerifier(
      appleCfg({
        verifyJws: async () => ({
          bundleId: 'app.oracly',
          productId: MONTHLY,
          originalTransactionId: 'orig-1',
        }),
        getSubscriptionStatuses: async () => ({
          statuses: [
            {
              status: Status.ACTIVE,
              productId: YEARLY,
              expiresDate: futureMs,
            },
          ],
        }),
      }),
    );
    const result = await verifier.verify({
      platform: 'ios',
      productId: MONTHLY,
      purchaseToken: 'a.b.c',
    });
    expect(result.status).toBe('unverified');
    expect(result.status).not.toBe('active');
  });

  it('P0-4 newer ACTIVE beats older expired matching row', async () => {
    const { createAppleStoreVerifier } = await import(
      '../src/billing/apple-store.js'
    );
    const verifier = createAppleStoreVerifier(
      appleCfg({
        verifyJws: async () => ({
          bundleId: 'app.oracly',
          productId: MONTHLY,
          originalTransactionId: 'orig-1',
        }),
        getSubscriptionStatuses: async () => ({
          statuses: [
            {
              status: Status.EXPIRED,
              productId: MONTHLY,
              expiresDate: pastMs,
              purchaseDate: pastMs - 1000,
            },
            {
              status: Status.ACTIVE,
              productId: MONTHLY,
              expiresDate: laterMs,
              purchaseDate: futureMs,
            },
          ],
        }),
      }),
    );
    const result = await verifier.verify({
      platform: 'ios',
      productId: MONTHLY,
      purchaseToken: 'a.b.c',
    });
    expect(result.status).toBe('active');
  });


  it('P0-4 ACTIVE without expiry does not beat BILLING_RETRY with future expiry', async () => {
    const { createAppleStoreVerifier } = await import(
      '../src/billing/apple-store.js'
    );
    const verifier = createAppleStoreVerifier(
      appleCfg({
        verifyJws: async () => ({
          bundleId: 'app.oracly',
          productId: MONTHLY,
          originalTransactionId: 'orig-1',
        }),
        getSubscriptionStatuses: async () => ({
          statuses: [
            {
              status: Status.ACTIVE,
              productId: MONTHLY,
              purchaseDate: pastMs,
            },
            {
              status: Status.BILLING_RETRY,
              productId: MONTHLY,
              expiresDate: futureMs,
              purchaseDate: futureMs,
            },
          ],
        }),
      }),
    );
    const result = await verifier.verify({
      platform: 'ios',
      productId: MONTHLY,
      purchaseToken: 'a.b.c',
    });
    expect(result.status).toBe('active');
    expect(result.reason).toBe('billing_retry_entitled');
  });
  it('P0-4 all rows failed verification is unverified', async () => {
    const { createAppleStoreVerifier } = await import(
      '../src/billing/apple-store.js'
    );
    const verifier = createAppleStoreVerifier(
      appleCfg({
        verifyJws: async () => ({
          bundleId: 'app.oracly',
          productId: MONTHLY,
          originalTransactionId: 'orig-1',
        }),
        getSubscriptionStatuses: async () => ({ statuses: [] }),
      }),
    );
    const result = await verifier.verify({
      platform: 'ios',
      productId: MONTHLY,
      purchaseToken: 'a.b.c',
    });
    expect(result.status).toBe('unverified');
    expect(JSON.stringify(result).includes('"active"')).toBe(false);
  });

  it('security: client productId alone never grants without store evidence', async () => {
    const app = await testApp(billingTestConfig());
    const res = await post(app, {
      platform: 'android',
      productId: MONTHLY,
      purchaseToken: 'not-a-real-token',
      transactionId: 'spoof',
    });
    expect(res.json().status).not.toBe('active');
    await app.close();
  });
});

describe('Apple current-state chronology selection', () => {
  const tOld = Date.now() - 10_000_000;
  const tNew = Date.now() - 1_000;
  const future = Date.now() + 86_400_000;
  const past = Date.now() - 86_400_000;

  function appleCfg(
    overrides: Partial<
      import('../src/billing/apple-store.js').AppleStoreConfig
    > = {},
  ) {
    return {
      bundleId: 'app.oracly',
      appAppleId: 1,
      issuerId: 'issuer',
      keyId: 'key',
      privateKey: 'pem',
      rootCertificates: [Buffer.from('cert')],
      preferEnvironment: 'Production' as const,
      ...overrides,
    };
  }

  async function run(statuses: Array<Record<string, unknown>>) {
    const { createAppleStoreVerifier } = await import(
      '../src/billing/apple-store.js'
    );
    const verifier = createAppleStoreVerifier(
      appleCfg({
        verifyJws: async () => ({
          bundleId: 'app.oracly',
          productId: MONTHLY,
          originalTransactionId: 'orig-1',
        }),
        getSubscriptionStatuses: async () => ({
          statuses: statuses as never,
        }),
      }),
    );
    return verifier.verify({
      platform: 'ios',
      productId: MONTHLY,
      purchaseToken: 'a.b.c',
    });
  }

  it('old ACTIVE + newer REVOKED => inactive', async () => {
    const result = await run([
      {
        status: Status.ACTIVE,
        productId: MONTHLY,
        expiresDate: future,
        purchaseDate: tOld,
      },
      {
        status: Status.REVOKED,
        productId: MONTHLY,
        revocationDate: tNew,
        purchaseDate: tNew,
      },
    ]);
    expect(result.status).toBe('inactive');
    expect(result.status).not.toBe('active');
  });

  it('old GRACE + newer REVOKED => inactive', async () => {
    const result = await run([
      {
        status: Status.BILLING_GRACE_PERIOD,
        productId: MONTHLY,
        purchaseDate: tOld,
      },
      {
        status: Status.REVOKED,
        productId: MONTHLY,
        revocationDate: tNew,
        purchaseDate: tNew,
      },
    ]);
    expect(result.status).toBe('inactive');
  });

  it('old ACTIVE + newer EXPIRED => expired', async () => {
    const result = await run([
      {
        status: Status.ACTIVE,
        productId: MONTHLY,
        expiresDate: future,
        purchaseDate: tOld,
      },
      {
        status: Status.EXPIRED,
        productId: MONTHLY,
        expiresDate: past,
        purchaseDate: tNew,
      },
    ]);
    expect(result.status).toBe('expired');
    expect(result.status).not.toBe('active');
  });

  it('old GRACE + newer EXPIRED => expired', async () => {
    const result = await run([
      {
        status: Status.BILLING_GRACE_PERIOD,
        productId: MONTHLY,
        purchaseDate: tOld,
      },
      {
        status: Status.EXPIRED,
        productId: MONTHLY,
        expiresDate: past,
        purchaseDate: tNew,
      },
    ]);
    expect(result.status).toBe('expired');
  });

  it('old EXPIRED + newer ACTIVE future => active', async () => {
    const result = await run([
      {
        status: Status.EXPIRED,
        productId: MONTHLY,
        expiresDate: past,
        purchaseDate: tOld,
      },
      {
        status: Status.ACTIVE,
        productId: MONTHLY,
        expiresDate: future,
        purchaseDate: tNew,
      },
    ]);
    expect(result.status).toBe('active');
  });

  it('old EXPIRED + newer GRACE => active', async () => {
    const result = await run([
      {
        status: Status.EXPIRED,
        productId: MONTHLY,
        expiresDate: past,
        purchaseDate: tOld,
      },
      {
        status: Status.BILLING_GRACE_PERIOD,
        productId: MONTHLY,
        purchaseDate: tNew,
      },
    ]);
    expect(result.status).toBe('active');
    expect(result.reason).toBe('grace_period');
  });

  it('old ACTIVE + newer BILLING_RETRY future => retry active', async () => {
    const result = await run([
      {
        status: Status.ACTIVE,
        productId: MONTHLY,
        expiresDate: future,
        purchaseDate: tOld,
      },
      {
        status: Status.BILLING_RETRY,
        productId: MONTHLY,
        expiresDate: future,
        purchaseDate: tNew,
      },
    ]);
    expect(result.status).toBe('active');
    expect(result.reason).toBe('billing_retry_entitled');
  });

  it('old ACTIVE + newer BILLING_RETRY past => not stale ACTIVE', async () => {
    const result = await run([
      {
        status: Status.ACTIVE,
        productId: MONTHLY,
        expiresDate: future,
        purchaseDate: tOld,
      },
      {
        status: Status.BILLING_RETRY,
        productId: MONTHLY,
        expiresDate: past,
        purchaseDate: tNew,
      },
    ]);
    expect(result.status).toBe('pending');
    expect(result.status).not.toBe('active');
  });

  it('old ACTIVE + newer BILLING_RETRY missing expiry => not stale ACTIVE', async () => {
    const result = await run([
      {
        status: Status.ACTIVE,
        productId: MONTHLY,
        expiresDate: future,
        purchaseDate: tOld,
      },
      {
        status: Status.BILLING_RETRY,
        productId: MONTHLY,
        purchaseDate: tNew,
      },
    ]);
    expect(result.status).not.toBe('active');
    expect(result.status).toBe('unverified');
  });

  it('old REVOKED + newer ACTIVE purchase => active', async () => {
    const result = await run([
      {
        status: Status.REVOKED,
        productId: MONTHLY,
        revocationDate: tOld,
        purchaseDate: tOld,
      },
      {
        status: Status.ACTIVE,
        productId: MONTHLY,
        expiresDate: future,
        purchaseDate: tNew,
      },
    ]);
    expect(result.status).toBe('active');
  });

  it('same-status rows: newest purchaseDate wins', async () => {
    const result = await run([
      {
        status: Status.ACTIVE,
        productId: MONTHLY,
        expiresDate: future - 1000,
        purchaseDate: tOld,
      },
      {
        status: Status.ACTIVE,
        productId: MONTHLY,
        expiresDate: future,
        purchaseDate: tNew,
      },
    ]);
    expect(result.status).toBe('active');
  });

  it('unorderable ambiguous candidates never guess active', async () => {
    const ambiguous = await run([
      { status: Status.ACTIVE, productId: MONTHLY },
      { status: Status.EXPIRED, productId: MONTHLY },
    ]);
    expect(ambiguous.status).toBe('unverified');
    expect(ambiguous.reason).toBe('ambiguous_subscription_chronology');
    expect(ambiguous.status).not.toBe('active');
  });
});

describe('billing verify trust boundary', () => {
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

  it('requires Firebase auth when JWKS auth is configured', async () => {
    const app = await testApp(authedConfig(), undefined, {
      billing: {
        google: mockVerifier(async () => billingResult('active')),
      },
    });
    const res = await post(app, {
      platform: 'android',
      productId: YEARLY,
      purchaseToken: 'token-a',
    });
    expect(res.statusCode).toBe(401);
    await app.close();
  });

  it('binds an active purchase token to the authenticated identity', async () => {
    const { resetPurchaseBindingsForTests } = await import(
      '../src/billing/entitlement-binding.js'
    );
    resetPurchaseBindingsForTests();
    const app = await testApp(authedConfig(), undefined, {
      billing: {
        google: mockVerifier(async () => billingResult('active')),
      },
    });
    const tokenA = signHs256('billing-test-secret', {
      sub: 'user-a',
      iss: 'https://issuer.example',
      aud: 'oracly-ai',
    });
    const tokenB = signHs256('billing-test-secret', {
      sub: 'user-b',
      iss: 'https://issuer.example',
      aud: 'oracly-ai',
    });
    const payload = {
      platform: 'android',
      productId: YEARLY,
      purchaseToken: 'shared-store-token',
    };
    const first = await app.inject({
      method: 'POST',
      url: '/v1/billing/verify',
      headers: {
        authorization: `Bearer ${tokenA}`,
        'content-type': 'application/json',
      },
      payload,
    });
    expect(first.json().status).toBe('active');
    const second = await app.inject({
      method: 'POST',
      url: '/v1/billing/verify',
      headers: {
        authorization: `Bearer ${tokenB}`,
        'content-type': 'application/json',
      },
      payload,
    });
    expect(second.json()).toEqual({
      status: 'unverified',
      reason: 'purchase_bound_to_other_account',
    });
    await app.close();
  });
});
