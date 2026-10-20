/**
 * Store decision fixtures. No Play or App Store call is made.
 * A decoded payload is not a sandbox pass.
 */
import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { interpretAppleConsumable } from '../src/reading/reading-consumable-apple.js';
import { consumePlayPurchase, readPlayConsumable } from '../src/reading/reading-consumable-play.js';
import { createReadingConsumableVerifier } from '../src/reading/reading-consumable-verifier.js';
import { ReadingEntitlementLedger } from '../src/reading/reading-entitlement-ledger.js';
import { testConfig } from './helpers.js';

const owner = identityKeyFromSubject('user-a');

function jsonResponse(status: number, body?: unknown): Response {
  return new Response(body == null ? null : JSON.stringify(body), { status });
}

describe('consumable store decisions without a live store', () => {
  it('leaves the verifier closed when credentials are absent', () => {
    const verifier = createReadingConsumableVerifier(testConfig());
    expect(verifier.admitted).toBe(false);
    expect(verifier.androidAdmitted).toBe(false);
    expect(verifier.iosAdmitted).toBe(false);
  });

  it('grants only a completed Play purchase and retries consume', async () => {
    const seen: string[] = [];
    const fetchImpl = (async (url: string | URL) => {
      const text = String(url);
      seen.push(text);
      if (text.endsWith(':consume')) return jsonResponse(409);
      if (text.includes('pending-token')) return jsonResponse(200, { purchaseState: 2 });
      if (text.includes('canceled-token')) return jsonResponse(200, { purchaseState: 1, orderId: 'GPA.1' });
      if (text.includes('other-product')) return jsonResponse(200, { purchaseState: 0, orderId: 'GPA.2', productId: 'other' });
      return jsonResponse(200, { purchaseState: 0, orderId: 'GPA.9', consumptionState: 0 });
    }) as typeof fetch;
    const pending = await readPlayConsumable({
      fetchImpl, packageName: 'app.oracly', productId: 'app.oracly.reading.palm',
      purchaseToken: 'pending-token', accessToken: 'test-token',
    });
    const canceled = await readPlayConsumable({
      fetchImpl, packageName: 'app.oracly', productId: 'app.oracly.reading.palm',
      purchaseToken: 'canceled-token', accessToken: 'test-token',
    });
    const mismatch = await readPlayConsumable({
      fetchImpl, packageName: 'app.oracly', productId: 'app.oracly.reading.palm',
      purchaseToken: 'other-product', accessToken: 'test-token',
    });
    const bought = await readPlayConsumable({
      fetchImpl, packageName: 'app.oracly', productId: 'app.oracly.reading.palm',
      purchaseToken: 'valid-token', accessToken: 'test-token',
    });
    expect(pending).toMatchObject({ ok: false, reason: 'pending' });
    expect(canceled).toMatchObject({ ok: false, reason: 'canceled' });
    expect(mismatch).toMatchObject({ ok: false, reason: 'product_mismatch' });
    expect(bought).toMatchObject({ ok: true, transactionId: 'GPA.9' });
    const consumed = await consumePlayPurchase({
      fetchImpl, packageName: 'app.oracly', productId: 'app.oracly.reading.palm',
      purchaseToken: 'valid-token', accessToken: 'test-token',
    });
    expect(consumed).toBe('done');
    expect(seen.some((url) => url.includes('valid-token:consume'))).toBe(true);
  });

  it('rejects an Apple fixture that is revoked, mismatched, or not consumable', () => {
    const expected = {
      bundleId: 'app.oracly',
      productId: 'app.oracly.reading.coffee',
      environment: 'Sandbox' as const,
    };
    expect(interpretAppleConsumable({
      bundleId: 'app.oracly',
      productId: 'app.oracly.reading.coffee',
      transactionId: '1001',
      type: 'Consumable',
    }, expected)).toMatchObject({ ok: true, transactionId: '1001', environment: 'Sandbox' });
    expect(interpretAppleConsumable({
      bundleId: 'app.other', productId: 'app.oracly.reading.coffee', transactionId: '1001', type: 'Consumable',
    }, expected).ok).toBe(false);
    expect(interpretAppleConsumable({
      bundleId: 'app.oracly', productId: 'app.oracly.premium.monthly', transactionId: '1001', type: 'Consumable',
    }, { ...expected, productId: 'app.oracly.premium.monthly' }).ok).toBe(false);
    expect(interpretAppleConsumable({
      bundleId: 'app.oracly', productId: 'app.oracly.reading.coffee', transactionId: '1001',
      type: 'Consumable', revocationDate: 10,
    }, expected)).toMatchObject({ ok: false, reason: 'revoked' });
  });

  it('returns a stuck credit and does not treat a store refund as an in-app restore', async () => {
    const store = new MemoryDocumentStore();
    const ledger = new ReadingEntitlementLedger(store);
    await ledger.grantPurchase({
      ownerUserId: owner, platform: 'android', appId: 'app.oracly',
      productId: 'app.oracly.reading.palm',
      purchaseToken: 'token-1', transactionId: 'GPA.1', atMs: 1_000,
    });
    const operationId = 'a'.repeat(32);
    await ledger.consume({
      ownerUserId: owner, feature: 'palm', sourceRequestId: 'palm-stuck-01',
      operationId, atMs: 1_000,
    });
    expect((await ledger.balance(owner)).palm).toBe(0);
    const early = await ledger.reconcile({
      ownerUserId: owner, nowMs: 1_000, lookup: async () => null,
    });
    expect(early.restored).toBe(0);
    expect((await ledger.balance(owner)).palm).toBe(0);
    const healed = await ledger.reconcile({
      ownerUserId: owner, nowMs: 1_000 + 120_000, lookup: async () => null,
    });
    expect(healed.restored).toBe(1);
    expect((await ledger.balance(owner)).palm).toBe(1);
    await ledger.consume({
      ownerUserId: owner, feature: 'palm', sourceRequestId: 'palm-bound-01',
      operationId, atMs: 2_000,
    });
    const kept = await ledger.reconcile({
      ownerUserId: owner,
      nowMs: 2_000 + 120_000,
      lookup: async () => ({ ownerUserId: owner }),
    });
    expect(kept.bound).toBe(1);
    expect((await ledger.balance(owner)).palm).toBe(0);
    expect(await ledger.noteStoreRefund({
      ownerUserId: owner, platform: 'android', appId: 'app.oracly',
      purchaseToken: 'token-1', transactionId: 'GPA.1', atMs: 3_000,
    })).toBe('noted');
    expect((await ledger.balance(owner)).palm).toBe(0);
    const names = [...store.docs.values()].map((doc) => doc.name);
    expect(names).toContain('store_refund');
    expect(names.filter((name) => name === 'entitlement_restored')).toHaveLength(1);
  });
});
