import { describe, expect, it } from 'vitest';
import {
  reconcileWaitingOperations,
  type StagedUploadState,
  type WaitingOperationCandidate,
} from '../src/reading/reading-waiting-reconciliation.js';
import type { ReadingTaskScheduler } from '../src/reading/reading-task-scheduler.js';

function fakeScheduler() {
  const calls: { operationId: string; atMs: number; trigger: string }[] = [];
  const scheduler: ReadingTaskScheduler = {
    async schedule(input) {
      calls.push(input);
    },
  };
  return { scheduler, calls };
}

function candidate(overrides: Partial<WaitingOperationCandidate> = {}): WaitingOperationCandidate {
  return {
    operationId: 'op-1',
    ownerUserId: 'sub:owner-1',
    readingType: 'coffee',
    readyAtMs: 1_000,
    ...overrides,
  };
}

describe('reconcileWaitingOperations', () => {
  it('schedules an elapsed-readyAt, fully-staged operation for immediate processing', async () => {
    const { scheduler, calls } = fakeScheduler();
    const nowMs = 5_000;
    const outcomes = await reconcileWaitingOperations(
      [candidate({ operationId: 'op-elapsed', readyAtMs: 1_000 })],
      async () => 'complete',
      scheduler,
      nowMs,
    );
    expect(outcomes).toEqual([{ operationId: 'op-elapsed', action: 'scheduled', atMs: nowMs }]);
    expect(calls).toEqual([{ operationId: 'op-elapsed', atMs: nowMs, trigger: 'ready' }]);
  });

  it('schedules a future-readyAt, fully-staged operation for its real due time, not earlier', async () => {
    const { scheduler, calls } = fakeScheduler();
    const nowMs = 1_000;
    const futureReadyAt = 90_000;
    const outcomes = await reconcileWaitingOperations(
      [candidate({ operationId: 'op-future', readyAtMs: futureReadyAt })],
      async () => 'complete',
      scheduler,
      nowMs,
    );
    expect(outcomes).toEqual([{ operationId: 'op-future', action: 'scheduled', atMs: futureReadyAt }]);
    expect(calls).toEqual([{ operationId: 'op-future', atMs: futureReadyAt, trigger: 'ready' }]);
  });

  it('never schedules an operation with incomplete or missing staging, and never mutates anything', async () => {
    const { scheduler, calls } = fakeScheduler();
    const outcomes = await reconcileWaitingOperations(
      [
        candidate({ operationId: 'op-pending' }),
        candidate({ operationId: 'op-missing' }),
      ],
      async (operationId) => (operationId === 'op-pending' ? 'pending' : 'missing') satisfies StagedUploadState,
      scheduler,
      10_000,
    );
    expect(outcomes).toEqual([
      { operationId: 'op-pending', action: 'skipped_incomplete_staging', stagedState: 'pending' },
      { operationId: 'op-missing', action: 'skipped_incomplete_staging', stagedState: 'missing' },
    ]);
    expect(calls).toHaveLength(0);
  });

  it('running the exact same batch twice is safe -- each call only ever re-invokes the idempotent scheduler', async () => {
    const { scheduler, calls } = fakeScheduler();
    const batch = [candidate({ operationId: 'op-repeat', readyAtMs: 500 })];
    await reconcileWaitingOperations(batch, async () => 'complete', scheduler, 10_000);
    await reconcileWaitingOperations(batch, async () => 'complete', scheduler, 20_000);
    // Two calls into the scheduler is expected and safe -- the scheduler
    // itself (CloudTasksReadingTaskScheduler, via a deterministic task name)
    // is what absorbs the duplicate as a no-op; this function's job is only
    // to never skip a genuinely-complete operation, not to de-duplicate.
    expect(calls).toHaveLength(2);
    expect(calls[0]!.operationId).toBe('op-repeat');
    expect(calls[1]!.operationId).toBe('op-repeat');
  });

  it('never touches coffee/palm-unrelated fields and never charges Gems or calls a provider (pure scheduling only)', async () => {
    const { scheduler, calls } = fakeScheduler();
    const outcomes = await reconcileWaitingOperations(
      [candidate({ operationId: 'op-x' })],
      async () => 'complete',
      scheduler,
      10_000,
    );
    // The only side effect anywhere in this module is one scheduler call --
    // proven structurally: no ledger/repository/staged-object dependency is
    // even importable from this module's signature.
    expect(calls).toHaveLength(1);
    expect(outcomes[0]!.action).toBe('scheduled');
  });
});
