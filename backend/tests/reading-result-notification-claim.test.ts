import { describe, expect, it } from 'vitest';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { ReadingResultRepository } from '../src/reading/reading-result-repository.js';

/**
 * R2.1 Phase 4 — the durable pre-send notification-dispatch claim.
 * Proves the claim transaction itself, independent of the worker
 * pipeline: only one caller ever wins it, it never resets, and it is
 * silently absent (never crashes) on historical documents that predate
 * this field.
 */
describe('ReadingResultRepository.claimNotificationDispatch', () => {
  const baseRecord = {
    schemaVersion: 1 as const,
    operationId: 'op-claim-1',
    ownerUserId: 'owner-1',
    readingType: 'coffee' as const,
    resultId: 'coffee_op-claim-1',
    data: { overall: 'ready' },
    persistedAtMs: 1_000,
    notificationSentAtMs: null,
  };

  it('the first caller wins the claim', async () => {
    const store = new MemoryDocumentStore();
    const results = new ReadingResultRepository(store);
    await results.persistOnce(baseRecord);

    await expect(
      results.claimNotificationDispatch(baseRecord.operationId, 2_000),
    ).resolves.toBe('claimed');
  });

  it('a second (redelivered) caller observing the claim never wins it again', async () => {
    const store = new MemoryDocumentStore();
    const results = new ReadingResultRepository(store);
    await results.persistOnce(baseRecord);

    await expect(
      results.claimNotificationDispatch(baseRecord.operationId, 2_000),
    ).resolves.toBe('claimed');
    // Redelivery arriving after the claim but before any `markNotificationSent`
    // (e.g. a crash mid-send, or an ambiguous provider outcome) — must
    // observe the existing claim and refuse to hand out a second one.
    await expect(
      results.claimNotificationDispatch(baseRecord.operationId, 3_000),
    ).resolves.toBe('already_claimed');
    await expect(
      results.claimNotificationDispatch(baseRecord.operationId, 4_000),
    ).resolves.toBe('already_claimed');
  });

  it('once the dispatch is confirmed sent, the claim is permanently terminal', async () => {
    const store = new MemoryDocumentStore();
    const results = new ReadingResultRepository(store);
    await results.persistOnce(baseRecord);

    await results.claimNotificationDispatch(baseRecord.operationId, 2_000);
    await expect(
      results.markNotificationSent(baseRecord.operationId, 2_500),
    ).resolves.toBe(true);
    await expect(
      results.claimNotificationDispatch(baseRecord.operationId, 5_000),
    ).resolves.toBe('already_sent');
  });

  it('concurrent claim attempts on the same operation produce exactly one winner', async () => {
    const store = new MemoryDocumentStore();
    const results = new ReadingResultRepository(store);
    await results.persistOnce(baseRecord);

    const outcomes = await Promise.all([
      results.claimNotificationDispatch(baseRecord.operationId, 10),
      results.claimNotificationDispatch(baseRecord.operationId, 11),
      results.claimNotificationDispatch(baseRecord.operationId, 12),
    ]);
    expect(outcomes.filter((o) => o === 'claimed')).toHaveLength(1);
    expect(outcomes.filter((o) => o === 'already_claimed')).toHaveLength(2);
  });

  it('claiming for an operation with no persisted result yet is a safe not_found, never a crash', async () => {
    const store = new MemoryDocumentStore();
    const results = new ReadingResultRepository(store);
    await expect(
      results.claimNotificationDispatch('never-persisted', 1),
    ).resolves.toBe('not_found');
  });

  it('a historical document without the claim field is treated as unclaimed and remains readable', async () => {
    const store = new MemoryDocumentStore();
    // Simulates a pre-R2.1 document: no `notificationDispatchClaimedAtMs`
    // field was ever written for it.
    store.docs.set('readingOperationResults/legacy-op', {
      ...baseRecord,
      operationId: 'legacy-op',
      resultId: 'coffee_legacy-op',
    });
    const results = new ReadingResultRepository(store);

    const read = await results.get('legacy-op');
    expect(read?.notificationDispatchClaimedAtMs).toBeUndefined();
    expect(read?.data).toEqual(baseRecord.data);

    await expect(
      results.claimNotificationDispatch('legacy-op', 999),
    ).resolves.toBe('claimed');
  });
});
