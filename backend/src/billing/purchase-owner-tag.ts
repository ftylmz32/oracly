/**
 * Opaque per-account tag the app sends to Play as the obfuscated account
 * id when it launches a purchase. SHA-256 of the Firebase uid with a fixed
 * prefix: never reversible, never the raw uid. Must match the Flutter
 * `PremiumPurchaseAttemptStore.ownerTag` byte for byte.
 */
import { createHash } from 'node:crypto';

export function premiumOwnerTag(uid: string): string {
  return createHash('sha256')
    .update(`oracly.premium.owner:${uid}`, 'utf8')
    .digest('hex');
}
