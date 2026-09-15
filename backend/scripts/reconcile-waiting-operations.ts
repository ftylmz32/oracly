#!/usr/bin/env -S npx tsx
/**
 * Backfill Cloud Tasks for Coffee/Palm `waiting` operations created before
 * the durable scheduler existed. Safe to run any number of times.
 *
 * - Never mutates a readingOperations or staged-image record.
 * - The only write is scheduler.schedule(), which is itself idempotent
 *   (Cloud Tasks rejects a duplicate deterministic task name safely).
 * - Defaults to a dry run -- prints the classification and what it WOULD
 *   schedule, without calling Cloud Tasks. Pass --apply to actually schedule.
 *
 * Usage:
 *   npx tsx scripts/reconcile-waiting-operations.ts            # dry run
 *   npx tsx scripts/reconcile-waiting-operations.ts --apply    # schedules
 *
 * Run this right after promoting the durable-worker-capable revision to
 * production traffic -- not before, since a scheduled task's target URL is
 * the canonical production audience, and it will only succeed once that
 * revision is actually serving it.
 */
import { Firestore } from '@google-cloud/firestore';
import { loadConfig } from '../src/config.js';
import { createReadingTaskScheduler } from '../src/reading/reading-task-scheduler.js';
import {
  reconcileWaitingOperations,
  type StagedUploadState,
  type WaitingOperationCandidate,
} from '../src/reading/reading-waiting-reconciliation.js';

const OPERATIONS = 'readingOperations';
const STAGED_IMAGES = 'readingOperationStagedImages';

async function main() {
  const apply = process.argv.includes('--apply');
  const config = loadConfig(process.env);
  const firestore = new Firestore({ projectId: config.firebaseProjectId ?? undefined });

  const snap = await firestore
    .collection(OPERATIONS)
    .where('status', '==', 'waiting')
    .get();

  const candidates: WaitingOperationCandidate[] = [];
  for (const doc of snap.docs) {
    const data = doc.data();
    if (data.readingType !== 'coffee' && data.readingType !== 'palm') continue;
    candidates.push({
      operationId: doc.id,
      ownerUserId: String(data.ownerUserId),
      readingType: data.readingType,
      readyAtMs: Number(data.readyAtMs),
    });
  }

  console.log(`Found ${candidates.length} waiting Coffee/Palm operation(s).`);

  const stagedStatus = async (operationId: string): Promise<StagedUploadState> => {
    const doc = await firestore.collection(STAGED_IMAGES).doc(operationId).get();
    if (!doc.exists) return 'missing';
    const state = doc.data()?.uploadState;
    return state === 'complete' ? 'complete' : 'pending';
  };

  const scheduler = apply
    ? createReadingTaskScheduler(config)
    : {
        async schedule(input: { operationId: string; atMs: number }) {
          console.log(
            `[dry run] would schedule operationId=${input.operationId} atMs=${input.atMs} (${new Date(input.atMs).toISOString()})`,
          );
        },
      };

  const outcomes = await reconcileWaitingOperations(
    candidates,
    stagedStatus,
    scheduler,
    Date.now(),
  );

  const scheduled = outcomes.filter((o) => o.action === 'scheduled');
  const skipped = outcomes.filter((o) => o.action === 'skipped_incomplete_staging');
  console.log(`${apply ? 'Scheduled' : 'Would schedule'}: ${scheduled.length}`);
  for (const o of scheduled) console.log(`  - ${o.operationId} -> atMs=${(o as { atMs: number }).atMs}`);
  console.log(`Skipped (incomplete staging, left untouched): ${skipped.length}`);
  for (const o of skipped) {
    console.log(`  - ${o.operationId} (stagedState=${(o as { stagedState: string }).stagedState})`);
  }
  if (!apply) console.log('\nDry run only -- pass --apply to actually schedule tasks.');
}

main().catch((error) => {
  console.error('reconcile-waiting-operations FAIL:', error);
  process.exitCode = 1;
});
