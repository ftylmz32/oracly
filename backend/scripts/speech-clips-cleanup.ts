#!/usr/bin/env -S npx tsx
/**
 * Aşama 4C — inventory and cleanup of existing OR/Luna speech data.
 *
 * DEFAULT IS A READ-ONLY DRY RUN. It lists `speech-clips/` in the reading
 * staging bucket and reads `speechGrants` / `speechPreviewDay`, then prints
 * counts per decision (expired / orphan / stale probe / kept / skipped) and
 * how many records lack a Firestore TTL `expiresAt`. It prints no identity,
 * no reply text and no owner segment.
 *
 * Applying is a separate, Product-Owner-approved step. It requires ALL of:
 *   --apply
 *   --confirm-bucket=<the exact READING_STAGING_BUCKET>
 *   ORACLY_SPEECH_CLEANUP_APPROVED=yes   (environment)
 * and refuses plans larger than --max-deletes (default 500).
 *
 * Usage:
 *   npx tsx scripts/speech-clips-cleanup.ts                     # dry run
 *   ORACLY_SPEECH_CLEANUP_APPROVED=yes npx tsx scripts/speech-clips-cleanup.ts \
 *     --apply --confirm-bucket=<bucket> [--max-deletes=2000]
 *
 * Only objects under `speech-clips/` that match the clip / probe shape can be
 * selected (see `speech-retention.ts`); staged coffee / palm images and
 * SoulMate portraits in the same bucket are never listed.
 */
import { Firestore, Timestamp } from '@google-cloud/firestore';
import { Storage } from '@google-cloud/storage';
import { loadConfig } from '../src/config.js';
import {
  applySpeechCleanup,
  planSpeechCleanup,
  redactSpeechObjectName,
  SPEECH_RECORD_COLLECTIONS,
  type SpeechRecord,
} from '../src/reading/speech-cleanup-plan.js';
import { SPEECH_CLIP_PREFIX } from '../src/reading/speech-retention.js';

function flag(name: string): string | undefined {
  const hit = process.argv.find((arg) => arg.startsWith(`--${name}=`));
  return hit ? hit.slice(name.length + 3) : undefined;
}

async function main() {
  const config = loadConfig(process.env);
  const bucketName = config.readingStagingBucket;
  if (!config.firebaseProjectId || !bucketName) {
    throw new Error('speech_cleanup_requires_project_and_bucket');
  }
  const apply = process.argv.includes('--apply');
  if (apply) {
    if (flag('confirm-bucket') !== bucketName) throw new Error('speech_cleanup_confirm_bucket_mismatch');
    if (process.env.ORACLY_SPEECH_CLEANUP_APPROVED !== 'yes') throw new Error('speech_cleanup_not_approved');
  }
  const maxDeletes = Number(flag('max-deletes') ?? '500');
  if (!Number.isInteger(maxDeletes) || maxDeletes < 0) throw new Error('speech_cleanup_bad_max_deletes');

  const firestore = new Firestore({ projectId: config.firebaseProjectId, databaseId: config.firestoreDatabaseId });
  const bucket = new Storage({ projectId: config.firebaseProjectId }).bucket(bucketName);

  // Records first, objects second: a clip recorded after this snapshot is at
  // most seconds old and falls inside the orphan grace window.
  const records: SpeechRecord[] = [];
  for (const collection of SPEECH_RECORD_COLLECTIONS) {
    const snapshot = await firestore.collection(collection).get();
    for (const doc of snapshot.docs) records.push({ collection, id: doc.id, data: doc.data() });
  }
  const [files] = await bucket.getFiles({ prefix: SPEECH_CLIP_PREFIX });
  const objects = files.map((file) => {
    const created = Date.parse(String(file.metadata?.timeCreated ?? ''));
    return { name: file.name, createdMs: Number.isFinite(created) ? created : null };
  });

  const plan = planSpeechCleanup({ objects, records, nowMs: Date.now() });
  const byReason = plan.deleteObjects.reduce<Record<string, number>>((acc, item) => {
    acc[item.reason] = (acc[item.reason] ?? 0) + 1;
    return acc;
  }, {});
  console.log(JSON.stringify({
    mode: apply ? 'apply' : 'dry-run',
    scannedObjects: plan.scannedObjects,
    scannedRecords: plan.scannedRecords,
    deleteObjects: byReason,
    keptObjects: plan.keptObjects,
    skippedObjects: plan.skippedObjects,
    recordsWithoutExpiresAt: plan.backfillRecords.length,
    sample: plan.deleteObjects.slice(0, 5).map((item) => `${item.reason} ${redactSpeechObjectName(item.name)}`),
  }, null, 2));
  if (!apply) return;

  const result = await applySpeechCleanup(plan, {
    deleteObject: async (name) => { await bucket.file(name).delete({ ignoreNotFound: true }); },
    setRecordExpiresAt: async (collection, id, expiresAtMs) => {
      const ref = firestore.collection(collection).doc(id);
      await firestore.runTransaction(async (tx) => {
        const current = await tx.get(ref);
        // Never resurrect a deleted record or move an existing TTL instant.
        if (!current.exists || current.data()?.expiresAt !== undefined) return;
        tx.update(ref, { expiresAt: Timestamp.fromMillis(expiresAtMs) });
      });
    },
  }, { maxDeletes });
  console.log(JSON.stringify({ applied: result }, null, 2));
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : 'speech_cleanup_failed');
  process.exitCode = 1;
});
