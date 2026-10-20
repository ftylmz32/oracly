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
  | { ok: true; transactionId: string; environment?: 'Production' | 'Sandbox' }
  | {
      ok: false;
      reason:
        | 'store_not_admitted'
        | 'unverified'
        | 'provider_unavailable'
        | 'pending'
        | 'canceled'
        | 'revoked'
        | 'invalid'
        | 'product_mismatch'
        | 'bundle_mismatch';
    };

export type ConsumableVerifier = {
  readonly admitted: boolean;
  readonly androidAdmitted?: boolean;
  readonly iosAdmitted?: boolean;
  verify(request: ConsumableVerifyRequest): Promise<ConsumableVerifyResult>;
  consume?(request: ConsumableVerifyRequest): Promise<'done' | 'pending' | 'skipped'>;
};

export function createClosedConsumableVerifier(): ConsumableVerifier {
  return {
    admitted: false,
    androidAdmitted: false,
    iosAdmitted: false,
    verify(): Promise<ConsumableVerifyResult> {
      return Promise.resolve({ ok: false, reason: 'store_not_admitted' });
    },
  };
}
