/**
 * Aşama 4K — find data left behind for identities whose deletion was already
 * ACCEPTED (an older revision's incomplete sweep, or a late write from an old
 * worker during the traffic switch).
 *
 * Matching is exact, never heuristic: a receipt's document id is
 * sha256("account-delete\0" + identityKey) (`deletion-barrier.ts`), so each
 * owner value found in a collection is hashed and looked up. An owner without
 * an accepted receipt is never selected.
 *
 * Limitation (reported, not guessed): a `speech-clips/<owner>/` object whose
 * records are all gone cannot be tied to an identity (the owner segment is a
 * different hash); those are left to the age-based speech cleanup.
 */
import { accountDeletionReceiptId } from './deletion-barrier.js';

export type OwnedRecord = { collection: string; owner: string };
export type ReceiptState = 'accepted' | 'deleting' | 'other';

export type DeletionReconcilePlan = {
  /** Identities to re-sweep (exact receipt match). Not printed by the CLI. */
  identities: string[];
  leftoverByCollection: Record<string, number>;
  ownersScanned: number;
  ownersWithDeletingReceipt: number;
  ownersWithoutReceipt: number;
};

export function planDeletionReconcile(input: {
  records: OwnedRecord[];
  receipts: ReadonlyMap<string, ReceiptState>;
}): DeletionReconcilePlan {
  const owners = new Map<string, string[]>();
  for (const record of input.records) {
    if (typeof record.owner !== 'string' || record.owner.length === 0) continue;
    const list = owners.get(record.owner) ?? [];
    list.push(record.collection);
    owners.set(record.owner, list);
  }
  const plan: DeletionReconcilePlan = {
    identities: [],
    leftoverByCollection: {},
    ownersScanned: owners.size,
    ownersWithDeletingReceipt: 0,
    ownersWithoutReceipt: 0,
  };
  for (const [owner, collections] of owners) {
    const state = input.receipts.get(accountDeletionReceiptId(owner));
    if (state === 'accepted') {
      plan.identities.push(owner);
      for (const collection of collections) {
        plan.leftoverByCollection[collection] = (plan.leftoverByCollection[collection] ?? 0) + 1;
      }
    } else if (state === 'deleting') {
      plan.ownersWithDeletingReceipt += 1;
    } else {
      plan.ownersWithoutReceipt += 1;
    }
  }
  plan.identities.sort();
  return plan;
}

export type ReconcilePort = {
  reconcileDeletedIdentity(identity: string): Promise<
    { status: 'reconciled'; deletedDocuments: number; deletedObjects: number; anonymizedPurchaseBindings: number }
    | { status: 'skipped'; reason: string }
  >;
};

/** Applies a plan through the repository (which re-checks the accepted
 * receipt itself). Stops at the first failure; refuses plans over the cap. */
export async function applyDeletionReconcile(
  plan: DeletionReconcilePlan,
  port: ReconcilePort,
  options: { maxIdentities: number },
): Promise<{ reconciled: number; skipped: number; deletedDocuments: number; deletedObjects: number }> {
  if (plan.identities.length > options.maxIdentities) {
    throw new Error(`deletion_reconcile_over_cap:${plan.identities.length}>${options.maxIdentities}`);
  }
  const out = { reconciled: 0, skipped: 0, deletedDocuments: 0, deletedObjects: 0 };
  for (const identity of plan.identities) {
    const result = await port.reconcileDeletedIdentity(identity);
    if (result.status === 'skipped') {
      out.skipped += 1;
      continue;
    }
    out.reconciled += 1;
    out.deletedDocuments += result.deletedDocuments;
    out.deletedObjects += result.deletedObjects;
  }
  return out;
}
