/**
 * Aşama 4K/4L — deletion reconciliation CLI (compiled into the image so it
 * can run as a job under an environment-scoped service account).
 *
 * Target safety (4L): QA and production Firestore live in the SAME project,
 * so the project alone proves nothing. Every run — dry run included — needs
 * the database, bucket and project given EXPLICITLY in the environment AND
 * repeated as flags; nothing falls back to `(default)`. The Firestore and
 * Storage clients are built from that verified target only.
 *
 *   FIREBASE_PROJECT_ID=<p> FIRESTORE_DATABASE_ID=<db> READING_STAGING_BUCKET=<b> \
 *     node dist/account/deletion-reconcile-cli.js --project=<p> --database=<db> --bucket=<b>
 *   ... --apply   (+ ORACLY_DELETION_RECONCILE_APPROVED=yes, --max-identities=N)
 *
 * Output: counts only — never an identity, document id or content.
 */
import { pathToFileURL } from 'node:url';
import { Firestore } from '@google-cloud/firestore';
import { Storage } from '@google-cloud/storage';
import {
  DELETE_COLLECTIONS,
  FirestoreAccountDeletionRepository,
  IDENTITY_COLLECTIONS,
  SPEECH_COLLECTIONS,
} from './account-deletion.js';
import { ACCOUNT_DELETION_RECEIPTS } from './deletion-barrier.js';
import {
  applyDeletionReconcile,
  planDeletionReconcile,
  type OwnedRecord,
  type ReceiptState,
} from './deletion-reconcile-plan.js';

export type ReconcileTarget = {
  project: string;
  database: string;
  bucket: string;
  apply: boolean;
  maxIdentities: number;
};

function flag(argv: readonly string[], name: string): string | undefined {
  const hit = argv.find((arg) => arg.startsWith(`--${name}=`));
  return hit ? hit.slice(name.length + 3).trim() : undefined;
}

function explicit(env: NodeJS.ProcessEnv, key: string): string {
  const value = (env[key] ?? '').trim();
  if (!value) throw new Error(`deletion_reconcile_${key.toLowerCase()}_not_explicit`);
  return value;
}

/** Throws unless env and flags name exactly the same project, database and
 * bucket; apply additionally needs the approval variable. */
export function resolveReconcileTarget(argv: readonly string[], env: NodeJS.ProcessEnv): ReconcileTarget {
  const project = explicit(env, 'FIREBASE_PROJECT_ID');
  const database = explicit(env, 'FIRESTORE_DATABASE_ID');
  const bucket = explicit(env, 'READING_STAGING_BUCKET');
  if (flag(argv, 'project') !== project) throw new Error('deletion_reconcile_project_mismatch');
  if (flag(argv, 'database') !== database) throw new Error('deletion_reconcile_database_mismatch');
  if (flag(argv, 'bucket') !== bucket) throw new Error('deletion_reconcile_bucket_mismatch');
  const apply = argv.includes('--apply');
  if (apply && env.ORACLY_DELETION_RECONCILE_APPROVED !== 'yes') throw new Error('deletion_reconcile_not_approved');
  const maxIdentities = Number(flag(argv, 'max-identities') ?? '25');
  if (!Number.isInteger(maxIdentities) || maxIdentities < 0) throw new Error('deletion_reconcile_bad_cap');
  return { project, database, bucket, apply, maxIdentities };
}

export async function runDeletionReconcile(argv: readonly string[], env: NodeJS.ProcessEnv): Promise<void> {
  const target = resolveReconcileTarget(argv, env);
  const firestore = new Firestore({ projectId: target.project, databaseId: target.database });
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
    mode: target.apply ? 'apply' : 'dry-run',
    database: target.database,
    bucket: target.bucket,
    receipts: { total: receipts.size, accepted: [...receipts.values()].filter((s) => s === 'accepted').length },
    ownersScanned: plan.ownersScanned,
    identitiesToReconcile: plan.identities.length,
    leftoverRecordsByCollection: plan.leftoverByCollection,
    ownersWithDeletingReceipt: plan.ownersWithDeletingReceipt,
  }));
  if (!target.apply) return;
  const repository = new FirestoreAccountDeletionRepository(
    firestore, new Storage({ projectId: target.project }), target.bucket,
  );
  const result = await applyDeletionReconcile(plan, repository, { maxIdentities: target.maxIdentities });
  console.log(JSON.stringify({ applied: result }));
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  runDeletionReconcile(process.argv.slice(2), process.env).catch((error) => {
    console.error(error instanceof Error ? error.message : 'deletion_reconcile_failed');
    process.exitCode = 1;
  });
}
