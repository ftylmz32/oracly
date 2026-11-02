#!/usr/bin/env -S npx tsx
/**
 * Aşama 4K — one-off reconciliation of data left behind for ACCEPTED
 * account deletions (older revision's incomplete sweep; late writes from an
 * old worker during the traffic switch).
 *
 * DEFAULT IS A READ-ONLY DRY RUN. It reads receipt ids + status and only the
 * owner field (`ownerUserId` / `identity`) of the owner-scoped collections
 * (field mask), matches each owner EXACTLY to its receipt id, and prints
 * counts only — never an identity, document id or content.
 *
 * Apply (separate PO approval) requires ALL of:
 *   --apply  --confirm-project=<FIREBASE_PROJECT_ID>
 *   ORACLY_DELETION_RECONCILE_APPROVED=yes
 * and refuses plans larger than --max-identities (default 25). Each identity
 * is re-swept by `FirestoreAccountDeletionRepository.reconcileDeletedIdentity`,
 * which re-checks the accepted receipt itself.
 */
import { Firestore } from '@google-cloud/firestore';
import {
  createAccountDeletionRepository,
  DELETE_COLLECTIONS,
  FirestoreAccountDeletionRepository,
  IDENTITY_COLLECTIONS,
  SPEECH_COLLECTIONS,
} from '../src/account/account-deletion.js';
import { ACCOUNT_DELETION_RECEIPTS } from '../src/account/deletion-barrier.js';
import {
  applyDeletionReconcile,
  planDeletionReconcile,
  type OwnedRecord,
  type ReceiptState,
} from '../src/account/deletion-reconcile-plan.js';
import { loadConfig } from '../src/config.js';

function flag(name: string): string | undefined {
  const hit = process.argv.find((arg) => arg.startsWith(`--${name}=`));
  return hit ? hit.slice(name.length + 3) : undefined;
}

async function main() {
  const config = loadConfig(process.env);
  if (!config.firebaseProjectId) throw new Error('deletion_reconcile_requires_project');
  const apply = process.argv.includes('--apply');
  if (apply) {
    if (flag('confirm-project') !== config.firebaseProjectId) throw new Error('deletion_reconcile_confirm_project_mismatch');
    if (process.env.ORACLY_DELETION_RECONCILE_APPROVED !== 'yes') throw new Error('deletion_reconcile_not_approved');
  }
  const maxIdentities = Number(flag('max-identities') ?? '25');
  if (!Number.isInteger(maxIdentities) || maxIdentities < 0) throw new Error('deletion_reconcile_bad_cap');

  const firestore = new Firestore({ projectId: config.firebaseProjectId, databaseId: config.firestoreDatabaseId });
  const receipts = new Map<string, ReceiptState>();
  for (const doc of (await firestore.collection(ACCOUNT_DELETION_RECEIPTS).select('status').get()).docs) {
    const status = doc.get('status');
    receipts.set(doc.id, status === 'accepted' ? 'accepted' : status === 'deleting' ? 'deleting' : 'other');
  }
  const records: OwnedRecord[] = [];
  const scan = async (collection: string, field: string) => {
    for (const doc of (await firestore.collection(collection).select(field).get()).docs) {
      const owner = doc.get(field);
      if (typeof owner === 'string') records.push({ collection, owner });
    }
  };
  for (const c of DELETE_COLLECTIONS) await scan(c, 'ownerUserId');
  for (const c of [...IDENTITY_COLLECTIONS, ...SPEECH_COLLECTIONS]) await scan(c, 'identity');

  const plan = planDeletionReconcile({ records, receipts });
  console.log(JSON.stringify({
    mode: apply ? 'apply' : 'dry-run',
    receipts: { total: receipts.size, accepted: [...receipts.values()].filter((s) => s === 'accepted').length },
    ownersScanned: plan.ownersScanned,
    identitiesToReconcile: plan.identities.length,
    leftoverRecordsByCollection: plan.leftoverByCollection,
    ownersWithDeletingReceipt: plan.ownersWithDeletingReceipt,
    note: 'speech-clips objects with no remaining record cannot be matched; age-based speech cleanup covers them',
  }, null, 2));
  if (!apply) return;

  const repository = createAccountDeletionRepository(config);
  if (!(repository instanceof FirestoreAccountDeletionRepository)) throw new Error('deletion_reconcile_repository_unavailable');
  const result = await applyDeletionReconcile(plan, repository, { maxIdentities });
  console.log(JSON.stringify({ applied: result }, null, 2));
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : 'deletion_reconcile_failed');
  process.exitCode = 1;
});
