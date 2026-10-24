/**
 * #44 — a Play purchase launched by the app carries the buyer's obfuscated
 * account tag (SHA-256 of the Firebase uid). The verifier reads it from
 * Play, and the verify route refuses (never binds) a purchase whose tag
 * names another account, whatever its status. The tag stays server-side:
 * it never reaches the client response. Untagged purchases keep the
 * existing first-claim binding.
 */
import { describe, expect, it } from 'vitest';
import { createGooglePlayVerifier } from '../src/billing/google-play.js';
import { premiumOwnerTag } from '../src/billing/purchase-owner-tag.js';
import type { BillingVerifyResult, StoreVerifier } from '../src/billing/types.js';
import { billingResult } from '../src/billing/types.js';
import { signHs256, testApp, testConfig } from './helpers.js';

const MONTHLY = 'app.oracly.premium.monthly';
const LIFETIME = 'app.oracly.premium.lifetime';

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

function verifierReturning(result: BillingVerifyResult): StoreVerifier {
  return {
    get configured() {
      return true;
    },
    verify: async () => result,
  };
}

async function appWith(result: BillingVerifyResult) {
  const { InMemoryEntitlementRepository } = await import(
    '../src/billing/entitlement-repository.js'
  );
  return testApp(authedConfig(), undefined, {
    billing: { google: verifierReturning(result) },
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

describe('owner tag', () => {
  it('matches the Flutter client byte for byte', () => {
    // Same constant as test/features/premium/premium_owner_tag_parity_test.dart
    expect(premiumOwnerTag('uid-account-a')).toBe(
      '34ab4ceb725c03573ce3b1659380289077c75df9d3ece5fc2eb12ddbc4ca76d5',
    );
  });
});

describe('Play reports who a purchase was launched for', () => {
  const verifier = (body: Record<string, unknown>) =>
    createGooglePlayVerifier({
      packageName: 'app.oracly',
      credentials: { client_email: 'x', private_key: 'y' },
      getAccessToken: async () => 'access',
      fetchImpl: async () =>
        new Response(JSON.stringify(body), {
          status: 200,
          headers: { 'content-type': 'application/json' },
        }),
    });

  it('subscription: externalAccountIdentifiers.obfuscatedExternalAccountId',
    async () => {
      const result = await verifier({
        subscriptionState: 'SUBSCRIPTION_STATE_PENDING',
        lineItems: [{ productId: MONTHLY }],
        externalAccountIdentifiers: {
          obfuscatedExternalAccountId: premiumOwnerTag('user-a'),
        },
      }).verify({
        platform: 'android',
        productId: MONTHLY,
        purchaseToken: 'tok',
      });
      expect(result.status).toBe('pending');
      expect(result.accountTag).toBe(premiumOwnerTag('user-a'));
    });

  it('one-time product: obfuscatedExternalAccountId', async () => {
    const result = await verifier({
      purchaseState: 1,
      obfuscatedExternalAccountId: premiumOwnerTag('user-a'),
    }).verify({ platform: 'android', productId: LIFETIME, purchaseToken: 'tok' });
    expect(result).toMatchObject({
      status: 'inactive',
      reason: 'product_canceled',
      accountTag: premiumOwnerTag('user-a'),
    });
  });

  it('a cancelled pending subscription is a definitive, named outcome',
    async () => {
      const result = await verifier({
        subscriptionState: 'SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED',
        lineItems: [{ productId: MONTHLY }],
      }).verify({
        platform: 'android',
        productId: MONTHLY,
        purchaseToken: 'tok',
      });
      expect(result).toMatchObject({
        status: 'inactive',
        reason: 'subscription_state_pending_purchase_canceled',
      });
    });
});

describe('the verify route honours the Play account tag', () => {
  it('another account\'s tagged purchase is refused and not bound, so its '
    + 'real owner can still claim it', async () => {
    const app = await appWith({
      ...billingResult('active', 'subscription_active'),
      accountTag: premiumOwnerTag('user-b'),
    });
    expect(await verifyAs(app, 'user-a')).toEqual({
      status: 'unverified',
      reason: 'purchase_bound_to_other_account',
    });
    expect(await verifyAs(app, 'user-b')).toEqual({
      status: 'active',
      reason: 'subscription_active',
    });
    await app.close();
  });

  it('another account\'s pending purchase is not reported to the caller',
    async () => {
      const app = await appWith({
        ...billingResult('pending', 'subscription_pending'),
        accountTag: premiumOwnerTag('user-b'),
      });
      expect(await verifyAs(app, 'user-a')).toEqual({
        status: 'unverified',
        reason: 'purchase_bound_to_other_account',
      });
      await app.close();
    });

  it('the buyer\'s own tagged purchase verifies; the tag never reaches the '
    + 'client', async () => {
    const app = await appWith({
      ...billingResult('active', 'subscription_active'),
      accountTag: premiumOwnerTag('user-a'),
    });
    const body = await verifyAs(app, 'user-a');
    expect(body).toEqual({ status: 'active', reason: 'subscription_active' });
    expect(JSON.stringify(body)).not.toContain(premiumOwnerTag('user-a'));
    await app.close();
  });

  it('an untagged (legacy) purchase keeps the first-claim binding', async () => {
    const app = await appWith(billingResult('active', 'product_purchased'));
    expect((await verifyAs(app, 'user-a')).status).toBe('active');
    expect(await verifyAs(app, 'user-b')).toEqual({
      status: 'unverified',
      reason: 'purchase_bound_to_other_account',
    });
    await app.close();
  });
});
