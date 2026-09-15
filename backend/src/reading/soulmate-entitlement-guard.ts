/**
 * SMD1 §7 / SMD1-E1 — server-side Premium check before the durable worker
 * ever calls a paid Soulmate provider. A client-reported "I'm Premium"
 * boolean is never sufficient; this is the authority.
 *
 * Reuses the SAME authoritative entitlement data the rest of ORACLY's
 * billing already produces — no second purchase-truth system. Every
 * `/v1/billing/verify` call (`routes/billing.ts`) now persists a real
 * store-computed snapshot onto the identity's owned `purchaseBindings`
 * doc: `status`, `expiryAtMs` (subscriptions only; null for lifetime and
 * for states with no concrete expiry, e.g. grace period), `verifiedAtMs`,
 * `kind`. This guard reads that snapshot and proves CURRENT activity, not
 * merely "purchased at some point":
 *
 *   lifetime:      active while status === 'active' (revocation flips it)
 *   subscription:  active while status === 'active' AND now < expiryAtMs
 *   grace period:  active while status === 'active' AND the snapshot is
 *                  recent (no concrete expiry exists for grace; an
 *                  indefinitely-old grace snapshot must not be trusted
 *                  forever — see GRACE_TRUST_WINDOW_MS)
 *
 * A binding predating this change (no `status`/`kind` recorded) is
 * treated as insufficient data, not as "still active" — a past purchase
 * is not proof of a current one. The client's own periodic
 * PremiumEntitlementReconciler re-verification is what refreshes a stale
 * snapshot; this guard never itself calls Apple/Google.
 */
import type { Firestore } from '@google-cloud/firestore';
import { isKnownProduct } from '../billing/catalog.js';
import type { AppConfig } from '../config.js';
import { systemClock, toEpochMs, type ServerClock } from './clock.js';

/** No concrete expiry exists for a grace-period snapshot — bound how long
 * a snapshot in that state may be trusted without a fresh re-verification. */
export const SOULMATE_GRACE_TRUST_WINDOW_MS = 3 * 86_400_000;

export interface SoulmateEntitlementGuard {
  isPremiumActive(ownerUserId: string): Promise<boolean>;
}

type PurchaseBindingData = {
  productId?: unknown;
  status?: unknown;
  kind?: unknown;
  expiryAtMs?: unknown;
  verifiedAtMs?: unknown;
};

/** Pure, clock-injected so tests never depend on wall-clock time. */
export function isBindingCurrentlyActive(
  data: PurchaseBindingData,
  nowMs: number,
): boolean {
  const productId = String(data.productId ?? '');
  if (!isKnownProduct(productId)) return false;
  // A binding without a recorded status/kind predates authoritative-expiry
  // persistence (or was never verified) — a past purchase is not proof of
  // a current one.
  if (data.status !== 'active') return false;
  if (data.kind === 'lifetime') return true;
  if (data.kind !== 'subscription') return false;
  if (typeof data.expiryAtMs === 'number') {
    return nowMs < data.expiryAtMs;
  }
  // No concrete expiry recorded (e.g. grace period) — trust only a
  // recently-verified snapshot, never indefinitely.
  if (typeof data.verifiedAtMs !== 'number') return false;
  return nowMs - data.verifiedAtMs < SOULMATE_GRACE_TRUST_WINDOW_MS;
}

export class FirestoreSoulmateEntitlementGuard implements SoulmateEntitlementGuard {
  constructor(
    private readonly firestore: Firestore,
    private readonly clock: ServerClock = systemClock(),
  ) {}

  async isPremiumActive(ownerUserId: string): Promise<boolean> {
    try {
      const snap = await this.firestore
        .collection('purchaseBindings')
        .where('identityKey', '==', ownerUserId)
        .limit(10)
        .get();
      const nowMs = toEpochMs(this.clock.now());
      return snap.docs.some((doc) => isBindingCurrentlyActive(doc.data(), nowMs));
    } catch {
      // A storage failure must never silently grant access.
      return false;
    }
  }
}

/** In-memory, test/dev-only — never durable, never shared across instances. */
export class InMemorySoulmateEntitlementGuard implements SoulmateEntitlementGuard {
  private readonly premiumIdentities = new Set<string>();

  grant(ownerUserId: string): void {
    this.premiumIdentities.add(ownerUserId);
  }

  /** SM-RL1 — lets a test simulate entitlement lapsing mid-operation
   * (e.g. between a rate-limited attempt and its retry). */
  revoke(ownerUserId: string): void {
    this.premiumIdentities.delete(ownerUserId);
  }

  async isPremiumActive(ownerUserId: string): Promise<boolean> {
    return this.premiumIdentities.has(ownerUserId);
  }
}

/** Storage is unreachable/unconfigured — fail closed, never grant. */
export class FailClosedSoulmateEntitlementGuard implements SoulmateEntitlementGuard {
  async isPremiumActive(): Promise<boolean> {
    return false;
  }
}

let sharedFirestore: Firestore | null = null;

export function createSoulmateEntitlementGuard(
  config: AppConfig,
  firestoreFactory?: () => Firestore,
): SoulmateEntitlementGuard {
  if (!config.firebaseProjectId) return new FailClosedSoulmateEntitlementGuard();
  try {
    if (firestoreFactory) {
      sharedFirestore ??= firestoreFactory();
    }
    if (!sharedFirestore) return new FailClosedSoulmateEntitlementGuard();
    return new FirestoreSoulmateEntitlementGuard(sharedFirestore);
  } catch {
    return new FailClosedSoulmateEntitlementGuard();
  }
}
