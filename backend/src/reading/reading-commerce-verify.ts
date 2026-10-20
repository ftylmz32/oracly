/**
 * Consumable store admission. The live verifier stays closed: Play and
 * App Store product definitions, sandbox proof, and release approval are
 * not in this repository. A test may inject a verifier. A closed result
 * never grants a credit.
 */
import type { ReadingCommerceProductId } from './reading-commerce-catalog.js';

export type ConsumableVerifyRequest = {
  platform: 'android' | 'ios';
  productId: ReadingCommerceProductId;
  purchaseToken: string;
};

export type ConsumableVerifyResult =
  | { ok: true; transactionId: string }
  | { ok: false; reason: 'store_not_admitted' | 'unverified' | 'provider_unavailable' };

export type ConsumableVerifier = {
  readonly admitted: boolean;
  verify(request: ConsumableVerifyRequest): Promise<ConsumableVerifyResult>;
};

export function createClosedConsumableVerifier(): ConsumableVerifier {
  return {
    admitted: false,
    verify(): Promise<ConsumableVerifyResult> {
      return Promise.resolve({ ok: false, reason: 'store_not_admitted' });
    },
  };
}
