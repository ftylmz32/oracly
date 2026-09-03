/** Known Oracly Premium store product IDs — must match Flutter PremiumStoreCatalog. */

export type ProductKind = 'subscription' | 'lifetime';

export const PREMIUM_PRODUCTS = {
  'app.oracly.premium.monthly': 'subscription',
  'app.oracly.premium.yearly': 'subscription',
  'app.oracly.premium.lifetime': 'lifetime',
} as const satisfies Record<string, ProductKind>;

export type KnownProductId = keyof typeof PREMIUM_PRODUCTS;

export function productKind(productId: string): ProductKind | null {
  const kind = PREMIUM_PRODUCTS[productId as KnownProductId];
  return kind ?? null;
}

export function isKnownProduct(productId: string): productId is KnownProductId {
  return productKind(productId) != null;
}