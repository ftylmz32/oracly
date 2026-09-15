/** Billing verify outcomes — matches Flutter PremiumVerifyResult statuses. */

export type BillingStatus =
  | 'active'
  | 'inactive'
  | 'pending'
  | 'expired'
  | 'error'
  | 'unverified';

export type BillingVerifyResult = {
  status: BillingStatus;
  reason?: string;
  /**
   * SMD1-E1 — internal only, computed by the store verifiers when they
   * already have a concrete authoritative expiry (a subscription's
   * `expiryTime`/`expiresDate`). Never a Soulmate-specific value, never
   * client-supplied. `routes/billing.ts` MUST NOT forward this to the
   * client response — it exists only to let the route persist a real
   * expiry onto the existing `purchaseBindings` record, closing the
   * "purchase once, treated as Premium forever" gap. Absent for lifetime
   * products (no expiry concept) and for states with no concrete expiry
   * (grace period, pending, error, etc.).
   */
  expiryAtMs?: number;
};

export type BillingVerifyRequest = {
  platform: 'android' | 'ios';
  productId: string;
  purchaseToken: string;
  transactionId?: string;
};

export type StoreVerifier = {
  readonly configured: boolean;
  verify(request: BillingVerifyRequest): Promise<BillingVerifyResult>;
};

export type BillingProviders = {
  google?: StoreVerifier;
  apple?: StoreVerifier;
};

export function billingResult(
  status: BillingStatus,
  reason?: string,
  expiryAtMs?: number,
): BillingVerifyResult {
  const result: BillingVerifyResult = { status };
  if (reason) result.reason = reason;
  if (expiryAtMs != null) result.expiryAtMs = expiryAtMs;
  return result;
}