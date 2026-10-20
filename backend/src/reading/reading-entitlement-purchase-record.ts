import type { FirestoreLike, FirestoreTransactionLike } from '../billing/entitlement-repository.js';
import { ReadingEntitlementError } from './reading-entitlement-error.js';
import { readingDocId } from './reading-entitlement-ids.js';
import type { ReadingCommerceFeature, ReadingCommerceProductId } from './reading-commerce-catalog.js';

export type PurchaseGrantInput = {
  ownerUserId: string;
  platform: 'android' | 'ios';
  appId: string;
  productId: ReadingCommerceProductId;
  purchaseToken: string;
  transactionId: string;
  atMs: number;
};

export const PURCHASES = 'readingEntitlementPurchases';
export const BALANCES = 'readingEntitlementBalances';
const EVENTS = 'readingCommerceEvents';

export type BalanceDoc = {
  coffee: number;
  palm: number;
  coffeePurchases: number;
  palmPurchases: number;
};

export function assertSamePurchase(
  data: Record<string, unknown> | undefined,
  input: PurchaseGrantInput,
): void {
  if (!data) throw new ReadingEntitlementError('invalid');
  if (data.ownerUserId !== input.ownerUserId) throw new ReadingEntitlementError('owned_by_other');
  if (typeof data.transactionId === 'string' && data.transactionId !== input.transactionId.trim()) {
    throw new ReadingEntitlementError('invalid');
  }
  if (typeof data.productId === 'string' && data.productId !== input.productId) {
    throw new ReadingEntitlementError('invalid');
  }
  if (typeof data.platform === 'string' && data.platform !== input.platform) {
    throw new ReadingEntitlementError('invalid');
  }
  if (typeof data.appId === 'string' && data.appId !== input.appId.trim()) {
    throw new ReadingEntitlementError('invalid');
  }
}

export function purchaseBody(
  input: PurchaseGrantInput,
  product: { feature: ReadingCommerceFeature; grants: number },
  existing: Record<string, unknown> | undefined,
): Record<string, unknown> {
  const units = unitsOf(existing) || product.grants;
  const remaining = typeof existing?.remaining === 'number' ? existing.remaining : units;
  return {
    ownerUserId: input.ownerUserId,
    platform: input.platform,
    appId: input.appId.trim(),
    productId: input.productId,
    feature: product.feature,
    units,
    remaining: existing ? remaining : product.grants,
    transactionId: input.transactionId.trim(),
    refunded: existing?.refunded === true,
  };
}

export function aliasBody(identityId: string, input: PurchaseGrantInput): Record<string, unknown> {
  return {
    alias: true,
    purchaseId: identityId,
    ownerUserId: input.ownerUserId,
    transactionId: input.transactionId.trim(),
  };
}

export function unitsOf(data: Record<string, unknown> | undefined): number {
  const value = data?.units;
  return typeof value === 'number' && Number.isInteger(value) && value > 0 ? value : 0;
}

export function readBalance(data: Record<string, unknown> | undefined): BalanceDoc {
  return {
    coffee: count(data, 'coffee'),
    palm: count(data, 'palm'),
    coffeePurchases: count(data, 'coffeePurchases'),
    palmPurchases: count(data, 'palmPurchases'),
  };
}

export function addBalance(balance: BalanceDoc, feature: ReadingCommerceFeature, delta: number): BalanceDoc {
  return { ...balance, [feature]: Math.max(0, balance[feature] + delta) };
}

export function writeEvent(
  tx: FirestoreTransactionLike,
  store: FirestoreLike,
  key: string,
  name: string,
  feature: ReadingCommerceFeature,
  input: { productId?: ReadingCommerceProductId; atMs: number },
  proposedTryMinor: number | null,
): void {
  tx.set(store.collection(EVENTS).doc(readingDocId(key)), {
    name,
    feature,
    productId: input.productId ?? null,
    proposedTryMinor,
    storeCutKnown: false,
    storeCutMicros: null,
    aiCostMicros: null,
    atMs: input.atMs,
  });
}

function count(data: Record<string, unknown> | undefined, key: string): number {
  const value = data?.[key];
  return typeof value === 'number' && Number.isInteger(value) && value > 0 ? value : 0;
}
