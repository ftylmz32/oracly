/**
 * iOS reading credits: the StoreKit 2 owner token is enforced on the
 * server, a purchase is credited once, refunds and revocations from App
 * Store Server Notifications take the credit back from the purchase's real
 * owner, and Play keeps working (legacy purchases without a tag included).
 * Fake store verifier and fake notification decoder only: no Apple call.
 */
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import type { JWSTransactionDecodedPayload } from '@apple/app-store-server-library';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { decodeSignedAppleTransaction } from '../src/billing/apple-store.js';
import {
  createAppleNotificationDecoder,
  type AppleNotificationDecoder,
} from '../src/reading/reading-apple-notifications.js';
import type { ConsumableVerifier, ConsumableVerifyResult } from '../src/reading/reading-commerce-verify.js';
import { interpretAppleConsumable } from '../src/reading/reading-consumable-apple.js';
import { interpretPlayConsumable } from '../src/reading/reading-consumable-play.js';
import { ReadingEntitlementLedger } from '../src/reading/reading-entitlement-ledger.js';
import { readingOwnerToken } from '../src/reading/reading-owner-token.js';
import { readingOwnerRefusal } from '../src/routes/reading-commerce.js';
import {
  StaticAppCheckVerifier,
  appCheckHeader,
  authHeader,
  signHs256,
  testApp,
  testConfig,
} from './helpers.js';

const SECRET = 'unit-test-jwt-secret';
const BUNDLE = 'app.oracly';
const USER_A_TOKEN = '434d797f-ce86-5c5e-8548-7bdd52c63fbc';

type FakeTx = { tag?: string | null; result?: ConsumableVerifyResult };

/** Purchase tokens name a scripted store answer. */
function scriptedVerifier(txs: Record<string, FakeTx>): ConsumableVerifier {
  return {
    admitted: true,
    iosAdmitted: true,
    androidAdmitted: true,
    async verify(request) {
      const tx = txs[request.purchaseToken];
      if (!tx) return { ok: false, reason: 'unverified' };
      return tx.result ?? {
        ok: true,
        transactionId: `tx-${request.purchaseToken}`,
        accountTag: tx.tag ?? null,
      };
    },
  };
}

async function harness(
  verifier: ConsumableVerifier,
  notifications: AppleNotificationDecoder | null = null,
) {
  const store = new MemoryDocumentStore();
  const app = await testApp(testConfig({
    AI_JWT_SECRET: SECRET,
    AI_APP_CHECK_REQUIRED: 'true',
    ORACLY_READING_COMMERCE_ENABLED: 'true',
    APPLE_BUNDLE_ID: BUNDLE,
  }), async () => {
    throw new Error('commerce must not call the provider');
  }, {
    appCheck: new StaticAppCheckVerifier('good-token'),
    gemStore: store,
    readingCommerceVerifier: verifier,
    readingAppleNotifications: notifications,
  });
  const headers = (sub = 'user-a') => ({
    ...authHeader(signHs256(SECRET, { sub })),
    ...appCheckHeader('good-token'),
  });
  const ledger = new ReadingEntitlementLedger(store);
  const coffee = async (sub = 'user-a') =>
    (await ledger.balance(identityKeyFromSubject(sub))).coffee;
  const verify = (token: string, sub = 'user-a', platform = 'ios', productId = 'app.oracly.reading.coffee') =>
    app.inject({
      method: 'POST',
      url: '/v1/reading-entitlements/verify',
      headers: headers(sub),
      payload: { platform, productId, purchaseToken: token },
    });
  return { app, store, coffee, verify };
}

describe('reading owner token', () => {
  it('matches the Flutter ReadingOwnerToken byte for byte', () => {
    expect(readingOwnerToken('user-a')).toBe(USER_A_TOKEN);
  });

  it('refuses iOS without a proven owner; Play only on a mismatch', () => {
    expect(readingOwnerRefusal('ios', USER_A_TOKEN, 'user-a')).toBeNull();
    expect(readingOwnerRefusal('ios', null, 'user-a')).toBe('owner_unproven');
    expect(readingOwnerRefusal('ios', USER_A_TOKEN, undefined)).toBe('owner_unproven');
    expect(readingOwnerRefusal('ios', USER_A_TOKEN, 'user-b')).toBe('purchase_bound_to_other_account');
    expect(readingOwnerRefusal('android', null, 'user-a')).toBeNull();
    expect(readingOwnerRefusal('android', USER_A_TOKEN, 'user-a')).toBeNull();
    expect(readingOwnerRefusal('android', USER_A_TOKEN, 'user-b')).toBe('purchase_bound_to_other_account');
  });

  it('reads the tag from the signed transaction and from Play, normalized', () => {
    const apple = interpretAppleConsumable(
      {
        bundleId: BUNDLE,
        productId: 'app.oracly.reading.palm',
        transactionId: '2000000123',
        type: 'Consumable',
        appAccountToken: USER_A_TOKEN.toUpperCase(),
      },
      { bundleId: BUNDLE, productId: 'app.oracly.reading.palm', environment: 'Sandbox' },
    );
    expect(apple).toMatchObject({ ok: true, accountTag: USER_A_TOKEN, environment: 'Sandbox' });
    const play = interpretPlayConsumable(
      { purchaseState: 0, orderId: 'GPA.1', obfuscatedExternalAccountId: USER_A_TOKEN },
      'app.oracly.reading.coffee',
    );
    expect(play).toMatchObject({ ok: true, accountTag: USER_A_TOKEN });
  });
});

describe('iOS verify', () => {
  it('credits the buyer once, however often the same purchase is sent', async () => {
    const { verify, coffee } = await harness(scriptedVerifier({ 'jws-1': { tag: USER_A_TOKEN } }));
    const first = await verify('jws-1');
    expect(first.json().data).toMatchObject({ granted: true, idempotent: false });
    const again = await verify('jws-1');
    expect(again.json().data).toMatchObject({ granted: true, idempotent: true });
    expect(await coffee()).toBe(1);
  });

  it("never credits another account's purchase; its owner still can", async () => {
    const { verify, coffee } = await harness(scriptedVerifier({ 'jws-a': { tag: USER_A_TOKEN } }));
    const stolen = await verify('jws-a', 'user-b');
    expect(stolen.json().data).toEqual({ granted: false, reason: 'purchase_bound_to_other_account' });
    expect(await coffee('user-b')).toBe(0);
    const own = await verify('jws-a', 'user-a');
    expect(own.json().data.granted).toBe(true);
    expect(await coffee('user-a')).toBe(1);
  });

  it('a transaction that names no owner is never credited', async () => {
    const { verify, coffee } = await harness(scriptedVerifier({ 'jws-none': { tag: null } }));
    expect((await verify('jws-none')).json().data).toEqual({ granted: false, reason: 'owner_unproven' });
    expect(await coffee()).toBe(0);
  });

  it('revoked or unverifiable purchases grant nothing', async () => {
    const { verify, coffee } = await harness(scriptedVerifier({
      'jws-revoked': { result: { ok: false, reason: 'revoked', transactionId: 'tx-r' } },
      'jws-down': { result: { ok: false, reason: 'provider_unavailable' } },
    }));
    expect((await verify('jws-revoked')).json().data.granted).toBe(false);
    expect((await verify('jws-forged')).json().data).toEqual({ granted: false, reason: 'unverified' });
    expect((await verify('jws-down')).json().data).toEqual({ granted: false, reason: 'provider_unavailable' });
    expect(await coffee()).toBe(0);
  });

  it('Play keeps working: untagged legacy purchases yes, another tag no', async () => {
    const { verify, coffee } = await harness(scriptedVerifier({
      'play-legacy': { tag: null },
      'play-other': { tag: readingOwnerToken('user-b') },
    }));
    expect((await verify('play-legacy', 'user-a', 'android')).json().data.granted).toBe(true);
    expect((await verify('play-other', 'user-a', 'android')).json().data.reason)
      .toBe('purchase_bound_to_other_account');
    expect(await coffee()).toBe(1);
  });
});

describe('App Store Server Notifications', () => {
  const transaction = (overrides: Partial<JWSTransactionDecodedPayload> = {}) => ({
    bundleId: BUNDLE,
    productId: 'app.oracly.reading.coffee',
    transactionId: 'tx-jws-1',
    ...overrides,
  }) as JWSTransactionDecodedPayload;

  function decoder(map: Record<string, { type: string; tx: JWSTransactionDecodedPayload }>): AppleNotificationDecoder {
    return async (signedPayload) => {
      const hit = map[signedPayload];
      return hit ? { notificationType: hit.type, transaction: hit.tx } : null;
    };
  }

  async function post(app: Awaited<ReturnType<typeof harness>>['app'], signedPayload: unknown) {
    return app.inject({
      method: 'POST',
      url: '/v1/reading-entitlements/apple-notifications',
      payload: { signedPayload },
    });
  }

  it('a refund takes the credit back from the real owner, once', async () => {
    const h = await harness(
      scriptedVerifier({ 'jws-1': { tag: USER_A_TOKEN } }),
      decoder({
        refund: { type: 'REFUND', tx: transaction() },
        revoke: { type: 'REVOKE', tx: transaction() },
      }),
    );
    await h.verify('jws-1');
    expect(await h.coffee()).toBe(1);
    const first = await post(h.app, 'refund');
    expect(first.statusCode).toBe(200);
    expect(first.json().data.outcome).toBe('noted');
    expect(await h.coffee()).toBe(0);
    expect((await post(h.app, 'refund')).json().data.outcome).toBe('already');
    expect((await post(h.app, 'revoke')).json().data.outcome).toBe('already');
    expect(await h.coffee()).toBe(0);
  });

  it('unverifiable, unrelated or not-yet-credited notifications change nothing', async () => {
    const h = await harness(
      scriptedVerifier({ 'jws-1': { tag: USER_A_TOKEN } }),
      decoder({
        other: { type: 'CONSUMPTION_REQUEST', tx: transaction() },
        premium: { type: 'REFUND', tx: transaction({ productId: 'app.oracly.premium.monthly' }) },
        foreign: { type: 'REFUND', tx: transaction({ bundleId: 'com.other.app' }) },
        early: { type: 'REFUND', tx: transaction({ transactionId: 'tx-never-verified' }) },
      }),
    );
    await h.verify('jws-1');
    expect((await post(h.app, 'forged')).statusCode).toBe(400);
    expect((await post(h.app, '')).statusCode).toBe(400);
    expect((await post(h.app, 'other')).json().data.outcome).toBe('ignored');
    expect((await post(h.app, 'premium')).json().data.outcome).toBe('ignored');
    expect((await post(h.app, 'foreign')).json().data.outcome).toBe('ignored');
    expect((await post(h.app, 'early')).json().data.outcome).toBe('absent');
    expect(await h.coffee()).toBe(1);
  });

  it('the real Apple verifiers reject forged payloads offline', async () => {
    // The same Apple roots the image ships (Dockerfile: certs/apple).
    const config = testConfig({
      APPLE_BUNDLE_ID: BUNDLE,
      APPLE_ROOT_CA_DIR: fileURLToPath(new URL('../certs/apple', import.meta.url)),
    });
    expect(config.appleRootCertificates.length).toBeGreaterThan(0);
    const decode = createAppleNotificationDecoder(config)!;
    const header = Buffer.from(JSON.stringify({ alg: 'ES256', x5c: ['bm90IGEgY2VydA=='] }))
      .toString('base64url');
    const body = Buffer.from(JSON.stringify({ notificationType: 'REFUND' })).toString('base64url');
    expect(await decode(`${header}.${body}.c2ln`)).toBeNull();
    expect(await decode('not-a-jws')).toBeNull();
    const decoded = await decodeSignedAppleTransaction(
      {
        bundleId: BUNDLE,
        appAppleId: null,
        issuerId: null,
        keyId: null,
        privateKey: null,
        rootCertificates: config.appleRootCertificates,
        preferEnvironment: 'Sandbox',
      },
      `${header}.${body}.c2ln`,
    );
    expect(decoded.ok).toBe(false);
  });

  it('without Apple configuration the endpoint refuses instead of guessing', async () => {
    const h = await harness(scriptedVerifier({}), null);
    expect((await post(h.app, 'anything')).statusCode).toBe(503);
  });
});
