/**
 * Durable purchase-token/transaction -> authenticated-uid entitlement
 * binding. Replaces the old in-process `Map` (entitlement-binding.ts),
 * which lost every binding on restart and never coordinated across
 * multiple Cloud Run instances — a purchase claimed on instance A was
 * invisible to instance B, so two different users could both be told a
 * shared/leaked purchase token was theirs.
 *
 * The binding decision is made by [claim], which must be atomic: it is the
 * single source of truth for "who owns this purchase," called once after a
 * successful store verification. [peekOwner] is a non-authoritative fast
 * path only, used to skip an Apple/Google API call when a token is already
 * obviously owned by someone else.
 */

import { createHash } from 'node:crypto';
import { Firestore, Timestamp } from '@google-cloud/firestore';
import type { AppConfig } from '../config.js';
import type { BillingStatus } from './types.js';

export type BindingClaimOutcome =
  | 'claimed'
  | 'already_owned'
  | 'owned_by_other'
  | 'error';

/**
 * SMD1-E1 — the authoritative-at-verify-time snapshot that closes the
 * "purchase once, treated as Premium forever" gap. `expiryAtMs` is the
 * real store-computed expiry (subscriptions only; null for lifetime and
 * for states with no concrete expiry, e.g. grace period). `verifiedAtMs`
 * is when THIS snapshot was taken — a reader must never trust an
 * indefinitely-old snapshot for a state that has no hard expiry of its
 * own (see SoulmateEntitlementGuard's grace-period freshness window).
 */
export type EntitlementStatusMeta = {
  status: BillingStatus;
  expiryAtMs: number | null;
  verifiedAtMs: number;
  kind: 'subscription' | 'lifetime';
};

export type BindingMeta = {
  platform: 'android' | 'ios';
  productId: string;
  transactionId?: string;
  /** SMD1-E1 — present whenever the caller has a fresh verify result to record. */
  entitlement?: EntitlementStatusMeta;
};

export type RecordStatusOutcome = 'recorded' | 'not_owned' | 'error';

export interface EntitlementBindingRepository {
  /**
   * Fast, non-authoritative pre-check — never the security decision.
   * Returns the owning identity if already known, or null if unbound or
   * unavailable (a lookup failure here must never grant access; it can
   * only skip a redundant store verification call).
   */
  peekOwner(bindingKey: string): Promise<string | null>;

  /**
   * The authoritative, atomic claim-or-check. Must only be called after a
   * store has confirmed the purchase is `active`. Creates the binding if
   * absent, is idempotent for the same owner, and rejects a different
   * owner — all as a single atomic operation so two concurrent requests
   * for the same token can never both win.
   */
  claim(
    bindingKey: string,
    identityKey: string,
    meta: BindingMeta,
  ): Promise<BindingClaimOutcome>;

  /**
   * SMD1-E1 — refreshes the CURRENT entitlement snapshot on a binding the
   * caller already owns, for every verify outcome (not just `active`) so
   * an expired/revoked subscription is reflected, not left looking
   * perpetually active. Never claims/creates ownership — a binding that
   * does not exist, or is owned by someone else, is left untouched.
   */
  recordStatus(
    bindingKey: string,
    identityKey: string,
    entitlement: EntitlementStatusMeta,
  ): Promise<RecordStatusOutcome>;
}

/** Purchase tokens can be large (Android, up to 64KB) — never a raw doc ID. */
export function purchaseBindingKey(
  platform: string,
  purchaseToken: string,
): string {
  return platform + ':' + purchaseToken;
}

/** SHA-256 hex digest — safe, bounded-length Firestore document ID. Never
 * reversible to the raw token, so the token itself need not be stored. */
function documentIdFor(bindingKey: string): string {
  return createHash('sha256').update(bindingKey).digest('hex');
}

const DEFAULT_COLLECTION = 'purchaseBindings';

/**
 * Narrow structural slice of `@google-cloud/firestore`'s `Firestore` that
 * this repository actually needs. The real `Firestore` client satisfies
 * this automatically; tests can supply a lightweight fake backed by a
 * plain object store, without depending on Firestore's wire protocol —
 * this is what makes the "restart/new instance" test meaningful: two
 * `FirestoreEntitlementRepository` instances wrapping the *same* fake
 * store prove the class itself holds no hidden process-local state.
 */
export type FirestoreDocSnapshotLike = {
  exists: boolean;
  data(): Record<string, unknown> | undefined;
};
export type FirestoreDocRefLike = {
  get(): Promise<FirestoreDocSnapshotLike>;
};
export type FirestoreCollectionLike = {
  doc(id: string): FirestoreDocRefLike;
};
export type FirestoreTransactionLike = {
  get(ref: FirestoreDocRefLike): Promise<FirestoreDocSnapshotLike>;
  set(ref: FirestoreDocRefLike, data: Record<string, unknown>): unknown;
  update(ref: FirestoreDocRefLike, data: Record<string, unknown>): unknown;
  /** BATCH 5I — staged-image metadata cleanup needs a real delete, not an update-to-empty. */
  delete(ref: FirestoreDocRefLike): unknown;
};
export type FirestoreLike = {
  collection(name: string): FirestoreCollectionLike;
  runTransaction<T>(
    fn: (tx: FirestoreTransactionLike) => Promise<T>,
  ): Promise<T>;
};

export class FirestoreEntitlementRepository
  implements EntitlementBindingRepository
{
  constructor(
    private readonly firestore: FirestoreLike,
    private readonly collection: string = DEFAULT_COLLECTION,
  ) {}

  async peekOwner(bindingKey: string): Promise<string | null> {
    try {
      const snap = await this.firestore
        .collection(this.collection)
        .doc(documentIdFor(bindingKey))
        .get();
      if (!snap.exists) return null;
      const identityKey = snap.data()?.identityKey;
      return typeof identityKey === 'string' ? identityKey : null;
    } catch {
      // Optimization only — a failed pre-check just means we fall through
      // to verification + the authoritative transactional claim below.
      return null;
    }
  }

  async claim(
    bindingKey: string,
    identityKey: string,
    meta: BindingMeta,
  ): Promise<BindingClaimOutcome> {
    const ref = this.firestore
      .collection(this.collection)
      .doc(documentIdFor(bindingKey));
    try {
      return await this.firestore.runTransaction<BindingClaimOutcome>(
        async (tx) => {
          const snap = await tx.get(ref);
          const entitlementFields = entitlementDocFields(meta.entitlement);
          if (!snap.exists) {
            tx.set(ref, {
              identityKey,
              platform: meta.platform,
              productId: meta.productId,
              transactionId: meta.transactionId ?? null,
              createdAt: Timestamp.now(),
              updatedAt: Timestamp.now(),
              ...entitlementFields,
            });
            return 'claimed';
          }
          const owner = snap.data()?.identityKey;
          // Account deletion removes current UID ownership but deliberately
          // retains a pseudonymous audit trail. Reaching claim still requires
          // a fresh authoritative store verification in the billing route.
          if (owner == null && snap.data()?.rebindEligible === true) {
            tx.update(ref, {
              identityKey,
              rebindEligible: false,
              previousOwnerHash: snap.data()?.previousOwnerHash ?? null,
              reboundAt: Timestamp.now(),
              updatedAt: Timestamp.now(),
              bindingGeneration:
                typeof snap.data()?.bindingGeneration === 'number'
                  ? (snap.data()?.bindingGeneration as number) + 1
                  : 2,
              ...entitlementFields,
            });
            return 'claimed';
          }
          if (owner === identityKey) {
            tx.update(ref, { updatedAt: Timestamp.now(), ...entitlementFields });
            return 'already_owned';
          }
          return 'owned_by_other';
        },
      );
    } catch {
      // A storage failure must never silently grant an entitlement —
      // the caller is expected to fail closed on 'error'.
      return 'error';
    }
  }

  async recordStatus(
    bindingKey: string,
    identityKey: string,
    entitlement: EntitlementStatusMeta,
  ): Promise<RecordStatusOutcome> {
    const ref = this.firestore
      .collection(this.collection)
      .doc(documentIdFor(bindingKey));
    try {
      return await this.firestore.runTransaction<RecordStatusOutcome>(
        async (tx) => {
          const snap = await tx.get(ref);
          if (!snap.exists) return 'not_owned';
          if (snap.data()?.identityKey !== identityKey) return 'not_owned';
          tx.update(ref, {
            updatedAt: Timestamp.now(),
            ...entitlementDocFields(entitlement),
          });
          return 'recorded';
        },
      );
    } catch {
      return 'error';
    }
  }
}

function entitlementDocFields(
  entitlement: EntitlementStatusMeta | undefined,
): Record<string, unknown> {
  if (!entitlement) return {};
  return {
    status: entitlement.status,
    expiryAtMs: entitlement.expiryAtMs,
    verifiedAtMs: entitlement.verifiedAtMs,
    kind: entitlement.kind,
  };
}

/**
 * Never durable, never shared across instances — development/test only.
 * Implements the same atomic-claim contract via a per-document promise
 * chain so concurrent-claim tests exercise real serialization semantics,
 * not just sequential calls.
 */
export class InMemoryEntitlementRepository
  implements EntitlementBindingRepository
{
  private readonly docs = new Map<
    string,
    { identityKey: string; entitlement?: EntitlementStatusMeta }
  >();
  private readonly queues = new Map<string, Promise<unknown>>();

  async peekOwner(bindingKey: string): Promise<string | null> {
    return this.docs.get(documentIdFor(bindingKey))?.identityKey ?? null;
  }

  async claim(
    bindingKey: string,
    identityKey: string,
    meta?: BindingMeta,
  ): Promise<BindingClaimOutcome> {
    const docId = documentIdFor(bindingKey);
    return this.enqueue(docId, () => {
      const existing = this.docs.get(docId);
      if (!existing) {
        this.docs.set(docId, { identityKey, entitlement: meta?.entitlement });
        return 'claimed';
      }
      if (existing.identityKey === identityKey) {
        existing.entitlement = meta?.entitlement ?? existing.entitlement;
        return 'already_owned';
      }
      return 'owned_by_other';
    });
  }

  async recordStatus(
    bindingKey: string,
    identityKey: string,
    entitlement: EntitlementStatusMeta,
  ): Promise<RecordStatusOutcome> {
    const docId = documentIdFor(bindingKey);
    return this.enqueue(docId, () => {
      const existing = this.docs.get(docId);
      if (!existing || existing.identityKey !== identityKey) return 'not_owned';
      existing.entitlement = entitlement;
      return 'recorded';
    });
  }

  private enqueue<T>(key: string, fn: () => T): Promise<T> {
    const prior = this.queues.get(key) ?? Promise.resolve();
    const run = prior.then(fn, fn);
    this.queues.set(
      key,
      run.then(
        () => undefined,
        () => undefined,
      ),
    );
    return run;
  }
}

/** Storage is unreachable/unconfigured and durability is required — never
 * grant, never silently fall back to a non-durable cache. */
export class FailClosedEntitlementRepository
  implements EntitlementBindingRepository
{
  async peekOwner(): Promise<string | null> {
    return null;
  }

  async claim(): Promise<BindingClaimOutcome> {
    return 'error';
  }

  async recordStatus(): Promise<RecordStatusOutcome> {
    return 'error';
  }
}

let sharedFirestore: Firestore | null = null;

export function createEntitlementRepository(
  config: AppConfig,
): EntitlementBindingRepository {
  if (!config.entitlementDurableRequired) {
    return new InMemoryEntitlementRepository();
  }
  if (!config.firebaseProjectId) {
    return new FailClosedEntitlementRepository();
  }
  try {
    sharedFirestore ??= new Firestore({
      projectId: config.firebaseProjectId,
      databaseId: config.firestoreDatabaseId,
    });
    return new FirestoreEntitlementRepository(sharedFirestore);
  } catch {
    return new FailClosedEntitlementRepository();
  }
}
