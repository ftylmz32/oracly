/**
 * Interprets an already-signed App Store transaction. This function does not
 * verify a signature and is not a sandbox pass.
 */
import { readingCommerceProduct } from './reading-commerce-catalog.js';

export type AppleConsumablePayload = {
  bundleId?: string | null;
  productId?: string | null;
  transactionId?: string | null;
  revocationDate?: number | null;
  type?: string | null;
};

export type AppleConsumableDecision =
  | { ok: true; transactionId: string; environment: 'Production' | 'Sandbox' }
  | { ok: false; reason: 'bundle_mismatch' | 'product_mismatch' | 'revoked' | 'invalid'; transactionId?: string };

export function interpretAppleConsumable(
  payload: AppleConsumablePayload,
  expected: { bundleId: string; productId: string; environment: 'Production' | 'Sandbox' },
): AppleConsumableDecision {
  if (!readingCommerceProduct(expected.productId)) return { ok: false, reason: 'invalid' };
  if (payload.bundleId && payload.bundleId !== expected.bundleId) {
    return { ok: false, reason: 'bundle_mismatch' };
  }
  if (!payload.productId || payload.productId !== expected.productId) {
    return { ok: false, reason: 'product_mismatch' };
  }
  const transactionId = payload.transactionId?.trim() ?? '';
  if (payload.revocationDate != null) {
    return { ok: false, reason: 'revoked', transactionId: transactionId || undefined };
  }
  if (payload.type != null && payload.type !== 'Consumable') return { ok: false, reason: 'invalid' };
  if (!transactionId) return { ok: false, reason: 'invalid' };
  return { ok: true, transactionId, environment: expected.environment };
}
