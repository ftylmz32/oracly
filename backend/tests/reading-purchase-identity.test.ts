/**
 * Purchase identity fixtures. No Play or App Store call is made.
 */
import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { ReadingEntitlementError } from '../src/reading/reading-entitlement-error.js';
import { purchaseTokenId, readingDocId } from '../src/reading/reading-entitlement-ids.js';
import { ReadingEntitlementLedger } from '../src/reading/reading-entitlement-ledger.js';

const owner = identityKeyFromSubject('user-a');
const other = identityKeyFromSubject('user-b');
const appId = 'app.oracly';

function ledger() {
  return new ReadingEntitlementLedger(new MemoryDocumentStore());
}

describe('store transaction identity without a live store', () => {
  it('grants one credit for two Apple JWS values of the same transaction', async () => {
    const entitlements = ledger();
    const first = await entitlements.grantPurchase({
      ownerUserId: owner, platform: 'ios', appId, productId: 'app.oracly.reading.coffee',
      purchaseToken: 'header.payload.sig-a', transactionId: '1001', atMs: 1,
    });
    const second = await entitlements.grantPurchase({
      ownerUserId: owner, platform: 'ios', appId, productId: 'app.oracly.reading.coffee',
      purchaseToken: 'header.payload.sig-b', transactionId: '1001', atMs: 2,
    });
    const lostResponse = await entitlements.grantPurchase({
      ownerUserId: owner, platform: 'ios', appId, productId: 'app.oracly.reading.coffee',
      purchaseToken: 'header.payload.sig-a', transactionId: '1001', atMs: 3,
    });
    expect(first.idempotent).toBe(false);
    expect(second.idempotent).toBe(true);
    expect(lostResponse.idempotent).toBe(true);
    expect((await entitlements.balance(owner)).coffee).toBe(1);
  });

  it('rejects the same transaction on another account or another product', async () => {
    const entitlements = ledger();
    await entitlements.grantPurchase({
      ownerUserId: owner, platform: 'ios', appId, productId: 'app.oracly.reading.coffee',
      purchaseToken: 'jws-a', transactionId: '1001', atMs: 1,
    });
    await expect(entitlements.grantPurchase({
      ownerUserId: other, platform: 'ios', appId, productId: 'app.oracly.reading.coffee',
      purchaseToken: 'jws-b', transactionId: '1001', atMs: 2,
    })).rejects.toMatchObject({ code: 'owned_by_other' });
    await expect(entitlements.grantPurchase({
      ownerUserId: owner, platform: 'ios', appId, productId: 'app.oracly.reading.palm',
      purchaseToken: 'jws-c', transactionId: '1001', atMs: 3,
    })).rejects.toBeInstanceOf(ReadingEntitlementError);
    expect((await entitlements.balance(owner)).coffee).toBe(1);
    expect((await entitlements.balance(owner)).palm).toBe(0);
  });

  it('keeps an old token record idempotent and backfills the transaction', async () => {
    const store = new MemoryDocumentStore();
    const entitlements = new ReadingEntitlementLedger(store);
    await store.runTransaction(async (tx) => {
      tx.set(store.collection('readingEntitlementPurchases').doc(purchaseTokenId('android', 'legacy-token')), {
        ownerUserId: owner,
        productId: 'app.oracly.reading.coffee',
        feature: 'coffee',
        units: 1,
        transactionId: 'GPA.legacy',
        refunded: false,
      });
      tx.set(store.collection('readingEntitlementBalances').doc(readingDocId(owner)), {
        coffee: 1, palm: 0, coffeePurchases: 1, palmPurchases: 0,
      });
    });
    const replay = await entitlements.grantPurchase({
      ownerUserId: owner, platform: 'android', appId, productId: 'app.oracly.reading.coffee',
      purchaseToken: 'legacy-token', transactionId: 'GPA.legacy', atMs: 4,
    });
    const otherJws = await entitlements.grantPurchase({
      ownerUserId: owner, platform: 'android', appId, productId: 'app.oracly.reading.coffee',
      purchaseToken: 'legacy-token-again', transactionId: 'GPA.legacy', atMs: 5,
    });
    expect(replay.idempotent).toBe(true);
    expect(otherJws.idempotent).toBe(true);
    expect((await entitlements.balance(owner)).coffee).toBe(1);
  });

  it('refunds one purchase without taking unused credits from another', async () => {
    const entitlements = ledger();
    await entitlements.grantPurchase({
      ownerUserId: owner, platform: 'android', appId, productId: 'app.oracly.reading.coffee',
      purchaseToken: 'single', transactionId: 'GPA.single', atMs: 1,
    });
    await entitlements.grantPurchase({
      ownerUserId: owner, platform: 'android', appId, productId: 'app.oracly.reading.coffee.pack3',
      purchaseToken: 'pack', transactionId: 'GPA.pack', atMs: 2,
    });
    expect((await entitlements.balance(owner)).coffee).toBe(4);
    expect(await entitlements.noteStoreRefund({
      ownerUserId: owner, platform: 'android', appId,
      purchaseToken: 'single', transactionId: 'GPA.single', atMs: 3,
    })).toBe('noted');
    expect((await entitlements.balance(owner)).coffee).toBe(3);
    expect(await entitlements.noteStoreRefund({
      ownerUserId: owner, platform: 'android', appId,
      purchaseToken: 'pack', transactionId: 'GPA.pack', atMs: 4,
    })).toBe('noted');
    expect((await entitlements.balance(owner)).coffee).toBe(0);
  });

  it('leaves a second unused purchase in place when the consumed one is refunded', async () => {
    const entitlements = ledger();
    await entitlements.grantPurchase({
      ownerUserId: owner, platform: 'android', appId, productId: 'app.oracly.reading.palm',
      purchaseToken: 'palm-a', transactionId: 'GPA.a', atMs: 1,
    });
    await entitlements.consume({
      ownerUserId: owner, feature: 'palm', sourceRequestId: 'palm-used',
      operationId: 'c'.repeat(32), atMs: 2,
    });
    await entitlements.grantPurchase({
      ownerUserId: owner, platform: 'android', appId, productId: 'app.oracly.reading.palm',
      purchaseToken: 'palm-b', transactionId: 'GPA.b', atMs: 3,
    });
    expect(await entitlements.noteStoreRefund({
      ownerUserId: owner, platform: 'android', appId,
      purchaseToken: 'palm-a', transactionId: 'GPA.a', atMs: 4,
    })).toBe('noted');
    expect((await entitlements.balance(owner)).palm).toBe(1);
    expect(await entitlements.noteStoreRefund({
      ownerUserId: owner, platform: 'android', appId,
      purchaseToken: 'palm-b', transactionId: 'GPA.b', atMs: 5,
    })).toBe('noted');
    expect((await entitlements.balance(owner)).palm).toBe(0);
  });
});
