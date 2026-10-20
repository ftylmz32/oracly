/**
 * A store transaction grants one credit record. The identity is
 * platform + app + transaction id, not the raw purchase token.
 * Apple can present the same transaction as another JWS.
 */
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import { ReadingEntitlementError } from './reading-entitlement-error.js';
import { purchaseIdentityId, purchaseTokenId, readingDocId } from './reading-entitlement-ids.js';
import { ENTITLEMENT_LOTS, appendLot, readLots } from './reading-entitlement-lots.js';
import { readingCommerceProduct } from './reading-commerce-catalog.js';
import {
  BALANCES,
  PURCHASES,
  addBalance,
  aliasBody,
  assertSamePurchase,
  purchaseBody,
  readBalance,
  writeEvent,
  type BalanceDoc,
  type PurchaseGrantInput,
} from './reading-entitlement-purchase-record.js';

export type { PurchaseGrantInput };

export async function grantReadingPurchase(
  store: FirestoreLike,
  input: PurchaseGrantInput,
): Promise<{ balance: BalanceDoc; idempotent: boolean }> {
  const product = readingCommerceProduct(input.productId);
  const appId = input.appId.trim();
  const transactionId = input.transactionId.trim();
  const purchaseToken = input.purchaseToken.trim();
  if (!product || !appId || !transactionId || !purchaseToken) {
    throw new ReadingEntitlementError('invalid');
  }
  const identityId = purchaseIdentityId(input.platform, appId, transactionId);
  const tokenId = purchaseTokenId(input.platform, purchaseToken);
  try {
    return await store.runTransaction(async (tx) => {
      const identityRef = store.collection(PURCHASES).doc(identityId);
      const tokenRef = store.collection(PURCHASES).doc(tokenId);
      const balanceRef = store.collection(BALANCES).doc(readingDocId(input.ownerUserId));
      const lotsRef = store.collection(ENTITLEMENT_LOTS).doc(readingDocId(input.ownerUserId));
      const identity = await tx.get(identityRef);
      const token = await tx.get(tokenRef);
      const balance = readBalance((await tx.get(balanceRef)).data());
      const tokenData = token.data();
      if (!identity.exists && tokenData?.alias === true) {
        assertSamePurchase(tokenData, input);
        throw new ReadingEntitlementError('invalid');
      }
      const seen = identity.exists ? identity.data() : tokenData;
      if (seen) {
        assertSamePurchase(seen, input);
        if (!identity.exists) tx.set(identityRef, purchaseBody(input, product, seen));
        if (!token.exists || tokenData?.alias !== true) tx.set(tokenRef, aliasBody(identityId, input));
        return { balance, idempotent: true };
      }
      const next = addBalance(balance, product.feature, product.grants);
      const purchases = product.feature === 'coffee' ? balance.coffeePurchases : balance.palmPurchases;
      next[product.feature === 'coffee' ? 'coffeePurchases' : 'palmPurchases'] = purchases + 1;
      const lots = appendLot(readLots((await tx.get(lotsRef)).data()), {
        purchaseId: identityId,
        feature: product.feature,
        remaining: product.grants,
        units: product.grants,
        refunded: false,
      });
      tx.set(balanceRef, next);
      tx.set(lotsRef, { items: lots });
      tx.set(identityRef, purchaseBody(input, product, undefined));
      tx.set(tokenRef, aliasBody(identityId, input));
      writeEvent(tx, store, `purchase:${identityId}`, 'purchase_completed', product.feature, input, product.proposedTryMinor);
      if (purchases >= 1) {
        writeEvent(tx, store, `repurchase:${identityId}`, 'repurchase', product.feature, input, product.proposedTryMinor);
      }
      return { balance: next, idempotent: false };
    });
  } catch (error) {
    if (error instanceof ReadingEntitlementError) throw error;
    throw new ReadingEntitlementError('unavailable');
  }
}
