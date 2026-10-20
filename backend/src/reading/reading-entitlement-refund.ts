import type { FirestoreDocRefLike, FirestoreLike, FirestoreTransactionLike } from '../billing/entitlement-repository.js';
import { ReadingEntitlementError } from './reading-entitlement-error.js';
import { purchaseIdentityId, purchaseTokenId, readingDocId } from './reading-entitlement-ids.js';
import { ENTITLEMENT_LOTS, protectedRemaining, readLots, refundLot } from './reading-entitlement-lots.js';
import type { ReadingCommerceFeature, ReadingCommerceProductId } from './reading-commerce-catalog.js';
import {
  BALANCES,
  PURCHASES,
  addBalance,
  readBalance,
  unitsOf,
  writeEvent,
} from './reading-entitlement-purchase-record.js';

export async function noteReadingPurchaseRefund(
  store: FirestoreLike,
  input: {
    ownerUserId: string;
    platform: 'android' | 'ios';
    appId: string;
    purchaseToken: string;
    transactionId?: string;
    atMs: number;
  },
): Promise<'noted' | 'absent' | 'already'> {
  const purchaseToken = input.purchaseToken.trim();
  const transactionId = input.transactionId?.trim() ?? '';
  const appId = input.appId.trim();
  if (!purchaseToken && !transactionId) return 'absent';
  return store.runTransaction(async (tx) => {
    const resolved = await resolvePurchase(store, tx, input.platform, appId, purchaseToken, transactionId);
    if (!resolved) return 'absent' as const;
    const data = resolved.data;
    if (data.ownerUserId !== input.ownerUserId) throw new ReadingEntitlementError('owned_by_other');
    if (data.refunded === true) return 'already' as const;
    const feature: ReadingCommerceFeature = data.feature === 'palm' ? 'palm' : 'coffee';
    const balanceRef = store.collection(BALANCES).doc(readingDocId(input.ownerUserId));
    const lotsRef = store.collection(ENTITLEMENT_LOTS).doc(readingDocId(input.ownerUserId));
    const balance = readBalance((await tx.get(balanceRef)).data());
    const lots = readLots((await tx.get(lotsRef)).data());
    const refunded = refundLot(lots, resolved.purchaseId);
    const drop = refunded.drop == null
      ? Math.min(unitsOf(data), Math.max(0, balance[feature] - protectedRemaining(lots, feature)))
      : Math.min(refunded.drop, balance[feature]);
    tx.set(balanceRef, addBalance(balance, feature, -drop));
    tx.set(lotsRef, { items: refunded.lots });
    tx.set(resolved.ref, { ...data, refunded: true, remaining: 0 });
    const productId = typeof data.productId === 'string' ? data.productId as ReadingCommerceProductId : undefined;
    writeEvent(tx, store, `store-refund:${resolved.purchaseId}`, 'store_refund', feature, {
      productId,
      atMs: input.atMs,
    }, null);
    return 'noted' as const;
  });
}

async function resolvePurchase(
  store: FirestoreLike,
  tx: FirestoreTransactionLike,
  platform: 'android' | 'ios',
  appId: string,
  purchaseToken: string,
  transactionId: string,
): Promise<{ ref: FirestoreDocRefLike; purchaseId: string; data: Record<string, unknown> } | null> {
  const identityId = appId && transactionId ? purchaseIdentityId(platform, appId, transactionId) : '';
  if (identityId) {
    const ref = store.collection(PURCHASES).doc(identityId);
    const snap = await tx.get(ref);
    const data = snap.data();
    if (snap.exists && data && data.alias !== true) return { ref, purchaseId: identityId, data };
  }
  if (!purchaseToken) return null;
  const tokenRef = store.collection(PURCHASES).doc(purchaseTokenId(platform, purchaseToken));
  const token = (await tx.get(tokenRef)).data();
  if (!token) return null;
  if (typeof token.transactionId === 'string' && transactionId && token.transactionId !== transactionId) {
    return null;
  }
  if (token.alias === true && typeof token.purchaseId === 'string') {
    const ref = store.collection(PURCHASES).doc(token.purchaseId);
    const data = (await tx.get(ref)).data();
    if (!data) return null;
    return { ref, purchaseId: token.purchaseId, data };
  }
  return { ref: tokenRef, purchaseId: purchaseTokenId(platform, purchaseToken), data: token };
}
