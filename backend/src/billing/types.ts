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
): BillingVerifyResult {
  return reason ? { status, reason } : { status };
}