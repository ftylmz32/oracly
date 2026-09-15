/**
 * One-time-safe backfill for Coffee/Palm `waiting` operations created before
 * the durable Cloud Tasks scheduler existed (so they never got a task).
 *
 * Never mutates a `readingOperations` or staged-image record directly --
 * the only write this performs is `scheduler.schedule()`, the SAME call the
 * normal request-serving paths already make, which is itself idempotent
 * (Cloud Tasks rejects a duplicate deterministic task name as a 409, mapped
 * to a safe no-op). Running this against the same operation twice, or
 * against an operation that already has a task, is always safe.
 *
 * Never charges Gems, never touches staged bytes, never calls the provider.
 * An operation with incomplete staging is left untouched -- it has nothing
 * to process yet, and scheduling a task for it would just waste a doomed
 * worker delivery.
 */
import type { ReadingTaskScheduler } from './reading-task-scheduler.js';

export type WaitingOperationCandidate = {
  operationId: string;
  ownerUserId: string;
  readingType: 'coffee' | 'palm';
  readyAtMs: number;
};

export type StagedUploadState = 'complete' | 'pending' | 'missing';

export type ReconciliationOutcome =
  | { operationId: string; action: 'scheduled'; atMs: number }
  | { operationId: string; action: 'skipped_incomplete_staging'; stagedState: StagedUploadState };

/**
 * @param stagedStatus Looks up ONLY the staged-image upload state for one
 * operation -- read-only, never a mutation.
 */
export async function reconcileWaitingOperations(
  candidates: WaitingOperationCandidate[],
  stagedStatus: (operationId: string) => Promise<StagedUploadState>,
  scheduler: ReadingTaskScheduler,
  nowMs: number,
): Promise<ReconciliationOutcome[]> {
  const outcomes: ReconciliationOutcome[] = [];
  for (const candidate of candidates) {
    const stagedState = await stagedStatus(candidate.operationId);
    if (stagedState !== 'complete') {
      outcomes.push({
        operationId: candidate.operationId,
        action: 'skipped_incomplete_staging',
        stagedState,
      });
      continue;
    }
    // Elapsed readyAt schedules for "now" (immediate processing); a future
    // readyAt keeps its real due time -- never earlier, never a shortcut.
    const atMs = Math.max(candidate.readyAtMs, nowMs);
    await scheduler.schedule({
      operationId: candidate.operationId,
      atMs,
      trigger: 'ready',
    });
    outcomes.push({ operationId: candidate.operationId, action: 'scheduled', atMs });
  }
  return outcomes;
}
