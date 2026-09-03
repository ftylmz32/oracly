/** In-process purchase-token ownership — one store token per Oracly identity. */

import { billingResult, type BillingVerifyResult } from './types.js';

const owners = new Map<string, string>();

export function purchaseBindingKey(
  platform: string,
  purchaseToken: string,
): string {
  return platform + ':' + purchaseToken;
}

export function checkPurchaseBinding(
  key: string,
  identityKey: string,
): BillingVerifyResult | null {
  const owner = owners.get(key);
  if (owner && owner !== identityKey) {
    return billingResult('unverified', 'purchase_bound_to_other_account');
  }
  return null;
}

export function recordPurchaseBinding(
  key: string,
  identityKey: string,
  active: boolean,
): void {
  if (active) {
    owners.set(key, identityKey);
  }
}

/** Test seam — production needs durable storage across instances. */
export function resetPurchaseBindingsForTests(): void {
  owners.clear();
}
