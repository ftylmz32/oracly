/**
 * Billing-only Play QA. The spend gate stays in force everywhere else.
 * The flag does nothing on the production service or the default database.
 */
export const PLAY_QA_DATABASE_ID = 'oracly-play-qa';
export const PLAY_QA_SERVICE = 'oracly-api-play-qa';

export function readingBillingQaActive(input: {
  requested: boolean;
  firestoreDatabaseId: string;
  serviceName: string | null;
}): boolean {
  return input.requested
    && input.firestoreDatabaseId === PLAY_QA_DATABASE_ID
    && input.serviceName === PLAY_QA_SERVICE;
}

/** QA may offer a store purchase while fulfillment and the spend guard stay shut. */
export function catalogPurchasable(input: {
  admitted: boolean;
  budgetOpen: boolean;
  billingQa: boolean;
}): boolean {
  return input.admitted && (input.billingQa || input.budgetOpen);
}

/** A paid, promo, or rewarded purchase is not a license-tester purchase. */
export function billingQaRejectsPurchase(
  billingQa: boolean,
  licenseTest: boolean | undefined,
): boolean {
  return billingQa && licenseTest !== true;
}
