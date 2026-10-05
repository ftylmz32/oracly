/**
 * WAVE 3.2 — server-side account-deletion barrier.
 *
 * The barrier IS the existing `accountDeletionReceipts/{receiptId}` document:
 * `deleteForIdentity` now writes it (status `deleting`, no TTL) BEFORE the
 * first destructive operation and finalizes it to `accepted` (30-day TTL) at
 * the end. Its mere existence — in either state — means "this identity is
 * being / has been deleted", and every durable worker write path that can
 * CREATE owner-scoped state reads it inside its own transaction and refuses
 * to write.
 *
 * Because the sweep's owner queries run strictly after the barrier commits,
 * every worker write is either committed before the barrier (and therefore
 * visible to — and removed by — the sweep) or observes the barrier and
 * writes nothing. There is no window in between.
 */
import { createHash } from 'node:crypto';
import type {
  FirestoreLike,
  FirestoreTransactionLike,
} from '../billing/entitlement-repository.js';

export const ACCOUNT_DELETION_RECEIPTS = 'accountDeletionReceipts';

export function accountDeletionReceiptId(identityKey: string): string {
  return createHash('sha256').update(`account-delete\0${identityKey}`).digest('hex');
}

/** Typed, never-retryable signal: the owner is deleted or being deleted. */
export class AccountDeletedError extends Error {
  constructor(readonly orphanCleanupFailed = false, cause?: unknown) {
    super('account_deleted', cause instanceof Error ? { cause } : undefined);
    this.name = 'AccountDeletedError';
  }
}

function barrierRef(firestore: FirestoreLike, ownerUserId: string) {
  return firestore.collection(ACCOUNT_DELETION_RECEIPTS).doc(accountDeletionReceiptId(ownerUserId));
}

/** Transactional check — must be called inside the same transaction as the
 * write it guards (and, per Firestore rules, before any tx write). */
export async function assertNoDeletionBarrier(
  tx: FirestoreTransactionLike,
  firestore: FirestoreLike,
  ownerUserId: string,
): Promise<void> {
  if ((await tx.get(barrierRef(firestore, ownerUserId))).exists) {
    throw new AccountDeletedError();
  }
}

/** Non-transactional read, only for guarding a side effect that cannot join
 * a transaction (a GCS upload). Always paired with a transactional re-check. */
export async function hasDeletionBarrier(
  firestore: FirestoreLike,
  ownerUserId: string,
): Promise<boolean> {
  return (await barrierRef(firestore, ownerUserId).get()).exists;
}

export function findAccountDeletedError(error: unknown): AccountDeletedError | null {
  let current: unknown = error;
  for (let i = 0; i < 6 && current != null; i++) {
    if (current instanceof AccountDeletedError) return current;
    current = current instanceof Error ? current.cause : null;
  }
  return null;
}
