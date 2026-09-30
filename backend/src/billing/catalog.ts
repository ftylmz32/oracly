/** Known Oracly Premium store product IDs — must match Flutter PremiumStoreCatalog. */

export type ProductKind = 'subscription' | 'lifetime';
export type StorePlatform = 'android' | 'ios';

type ProductDefinition = {
  kind: ProductKind;
  /**
   * PART 4B REPAIR A — the single authoritative server-side platform
   * allowlist for this product. Enforced centrally in `verify.ts` BEFORE
   * any provider call, and redundantly inside each provider's own entry
   * point (matching this file's existing `isKnownProduct` redundancy
   * convention) — never rely on client-side filtering (App/Play Store
   * catalog exposure) alone. iOS has no lifetime product; if App Store
   * Connect is ever misconfigured to expose one, this still fails closed.
   */
  allowedPlatforms: readonly StorePlatform[];
};

export const PREMIUM_PRODUCTS = {
  'app.oracly.premium.monthly': {
    kind: 'subscription',
    allowedPlatforms: ['android', 'ios'],
  },
  'app.oracly.premium.yearly': {
    kind: 'subscription',
    allowedPlatforms: ['android', 'ios'],
  },
  'app.oracly.premium.lifetime': {
    kind: 'lifetime',
    allowedPlatforms: ['android'],
  },
} as const satisfies Record<string, ProductDefinition>;

export type KnownProductId = keyof typeof PREMIUM_PRODUCTS;

export function productKind(productId: string): ProductKind | null {
  const definition = PREMIUM_PRODUCTS[productId as KnownProductId];
  return definition?.kind ?? null;
}

export function isKnownProduct(productId: string): productId is KnownProductId {
  return productKind(productId) != null;
}

/** PART 4B REPAIR A — true only when `productId` is both known AND
 * declared allowed for `platform`. False for an unknown product (that
 * case is `isKnownProduct`'s job to report separately) or a known
 * product not sold on that platform (e.g. iOS + lifetime). */
export function isProductAllowedForPlatform(
  productId: string,
  platform: string,
): boolean {
  const definition = PREMIUM_PRODUCTS[productId as KnownProductId];
  if (!definition) return false;
  return (definition.allowedPlatforms as readonly string[]).includes(platform);
}