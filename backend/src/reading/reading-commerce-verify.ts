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
  | {
      ok: true;
      transactionId: string;
      environment?: 'Production' | 'Sandbox';
      licenseTest?: boolean;
      /**
       * The account the store says the purchase was launched for
       * (StoreKit 2 `appAccountToken`, Play `obfuscatedExternalAccountId`),
       * normalized. The route compares it with the caller.
       */
      accountTag?: string | null;
    }
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
      transactionId?: string;
    };

export type ConsumableVerifier = {
  readonly admitted: boolean;
  readonly androidAdmitted?: boolean;
  readonly iosAdmitted?: boolean;
  verify(request: ConsumableVerifyRequest): Promise<ConsumableVerifyResult>;
  consume?(request: ConsumableVerifyRequest): Promise<'done' | 'pending' | 'skipped'>;
  /** Null means the voided list could not be read. Credits stay as they are. */
  listVoided?(): Promise<Array<{ orderId: string; purchaseToken: string }> | null>;
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
