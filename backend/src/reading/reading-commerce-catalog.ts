/**
 * Server-owned reading products. The minor amounts are commercial test
 * proposals in Turkish kuruş. They are not a charge. The store catalog is
 * the only price authority, and this server never accepts a client price.
 * Web iyzico is not implemented in this repository; no browser checkout is
 * added here, so a mobile client cannot be sent around the store.
 */
export const READING_COMMERCE_PRODUCTS = {
  'app.oracly.reading.coffee': {
    feature: 'coffee',
    grants: 1,
    proposedTryMinor: 6999,
  },
  'app.oracly.reading.palm': {
    feature: 'palm',
    grants: 1,
    proposedTryMinor: 4999,
  },
  'app.oracly.reading.coffee.pack3': {
    feature: 'coffee',
    grants: 3,
    proposedTryMinor: 17999,
  },
} as const;

export type ReadingCommerceProductId = keyof typeof READING_COMMERCE_PRODUCTS;
export type ReadingCommerceFeature = 'coffee' | 'palm';
export const READING_TRIAL_DAILY_CAP = 20;

export function readingCommerceProduct(productId: string) {
  return READING_COMMERCE_PRODUCTS[productId as ReadingCommerceProductId] ?? null;
}

export function readingCommerceProposals() {
  return (Object.entries(READING_COMMERCE_PRODUCTS) as Array<
    [ReadingCommerceProductId, (typeof READING_COMMERCE_PRODUCTS)[ReadingCommerceProductId]]
  >).map(([productId, product]) => ({
    productId,
    feature: product.feature,
    grants: product.grants,
    proposedTryMinor: product.proposedTryMinor,
    currency: 'TRY',
    proposal: true,
    chargeAuthority: 'store_catalog',
  }));
}
