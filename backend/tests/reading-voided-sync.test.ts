import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { readVoidedPurchases } from '../src/reading/reading-consumable-play.js';
import { ReadingEntitlementLedger } from '../src/reading/reading-entitlement-ledger.js';
import { listPlayVoidedPurchases, syncVoidedReadingPurchases } from '../src/reading/reading-voided-sync.js';

const owner = identityKeyFromSubject('user-a');
const other = identityKeyFromSubject('user-b');

describe('voided Play purchases', () => {
  it('reads order ids and ignores a broken list', () => {
    expect(readVoidedPurchases({
      voidedPurchases: [
        { orderId: 'GPA.1', purchaseToken: 'token-1' },
        { orderId: '  ', purchaseToken: 'token-2' },
        { purchaseToken: 'token-3' },
      ],
    })).toEqual([{ orderId: 'GPA.1', purchaseToken: 'token-1' }]);
    expect(readVoidedPurchases(null)).toEqual([]);
  });

  it('returns null when Play does not answer, so credits stay', async () => {
    const fetchImpl = (async () => new Response('no', { status: 503 })) as typeof fetch;
    expect(await listPlayVoidedPurchases({
      fetchImpl, packageName: 'app.oracly', accessToken: 'test-token',
    })).toBeNull();
  });

  it('drops one owned credit once and leaves every other purchase', async () => {
    const store = new MemoryDocumentStore();
    const ledger = new ReadingEntitlementLedger(store);
    const grant = {
      platform: 'android' as const,
      appId: 'app.oracly',
      atMs: 1_000,
    };
    await ledger.grantPurchase({
      ...grant, ownerUserId: owner, productId: 'app.oracly.reading.coffee',
      purchaseToken: 'coffee-token', transactionId: 'GPA.coffee',
    });
    await ledger.grantPurchase({
      ...grant, ownerUserId: owner, productId: 'app.oracly.reading.coffee.pack3',
      purchaseToken: 'pack-token', transactionId: 'GPA.pack',
    });
    await ledger.grantPurchase({
      ...grant, ownerUserId: owner, productId: 'app.oracly.reading.palm',
      purchaseToken: 'palm-token', transactionId: 'GPA.palm',
    });
    await ledger.grantPurchase({
      ...grant, ownerUserId: other, productId: 'app.oracly.reading.coffee',
      purchaseToken: 'other-token', transactionId: 'GPA.other',
    });
    const voided = [
      { orderId: 'GPA.coffee', purchaseToken: 'coffee-token' },
      { orderId: 'GPA.coffee', purchaseToken: 'coffee-token' },
      { orderId: 'GPA.unknown', purchaseToken: 'missing' },
      { orderId: 'GPA.other', purchaseToken: 'other-token' },
    ];
    const first = await syncVoidedReadingPurchases({
      store, ownerUserId: owner, appId: 'app.oracly', atMs: 2_000, voided,
    });
    expect(first).toEqual({ noted: 1, already: 0, skipped: 3 });
    expect(await ledger.balance(owner)).toMatchObject({ coffee: 3, palm: 1 });
    expect(await ledger.balance(other)).toMatchObject({ coffee: 1, palm: 0 });
    const second = await syncVoidedReadingPurchases({
      store, ownerUserId: owner, appId: 'app.oracly', atMs: 3_000, voided,
    });
    expect(second.noted).toBe(0);
    expect(second.already).toBe(1);
    expect(await ledger.balance(owner)).toMatchObject({ coffee: 3, palm: 1 });
  });
});
