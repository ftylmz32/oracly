import type { FirestoreLike } from '../billing/entitlement-repository.js';
import { Timestamp } from '@google-cloud/firestore';
import type { ReadingGenerationTrace } from './provider-stage-repository.js';

const RESULTS = 'readingOperationResults';

export type ReadingOperationResult = {
  schemaVersion: 1;
  operationId: string;
  ownerUserId: string;
  readingType: 'coffee' | 'palm' | 'soulmate';
  resultId: string;
  data: Record<string, unknown>;
  persistedAtMs: number;
  notificationSentAtMs: number | null;
  /** R2.1 — durable pre-send dispatch claim. Set the moment a worker wins
   * the right to attempt the FCM call, strictly BEFORE that call is made,
   * so a redelivered/concurrent worker observing this already set can
   * never send a second user-visible notification — regardless of
   * whether the original attempt ever reached `notificationSentAtMs`.
   * Absent on historical documents; treated identically to "unclaimed". */
  notificationDispatchClaimedAtMs?: number;
  generationTrace?: ReadingGenerationTrace;
};

/** R2.1 — outcome of `claimNotificationDispatch`. Only `'claimed'` means
 * this caller may proceed to actually call the provider; every other
 * outcome means some invocation (this one, a concurrent one, or an
 * earlier one before a redelivery) already has — or had — that right. */
export type NotificationDispatchClaim =
  | 'claimed'
  | 'already_claimed'
  | 'already_sent'
  | 'not_found';

export class ReadingResultRepository {
  constructor(private readonly firestore: FirestoreLike) {}

  async get(operationId: string): Promise<ReadingOperationResult | null> {
    const snap = await this.firestore.collection(RESULTS).doc(operationId).get();
    return parseResult(snap.data());
  }

  async persistOnce(record: ReadingOperationResult): Promise<ReadingOperationResult> {
    const ref = this.firestore.collection(RESULTS).doc(record.operationId);
    return this.firestore.runTransaction(async (tx) => {
      const existing = parseResult((await tx.get(ref)).data());
      if (existing) return existing;
      tx.set(ref, { ...record, expiresAt: Timestamp.fromMillis(record.persistedAtMs + 30 * 86_400_000) });
      return record;
    });
  }

  async markNotificationSent(operationId: string, atMs: number): Promise<boolean> {
    const ref = this.firestore.collection(RESULTS).doc(operationId);
    return this.firestore.runTransaction(async (tx) => {
      const current = parseResult((await tx.get(ref)).data());
      if (!current || current.notificationSentAtMs != null) return false;
      tx.set(ref, { ...current, notificationSentAtMs: atMs });
      return true;
    });
  }

  /** R2.1 — transactionally claims the exclusive right to attempt the
   * completion push BEFORE any provider network call is made. Firestore's
   * own optimistic-concurrency retry on this transaction is what makes
   * "only one winner" true under real concurrent/redelivered invocations,
   * not application-level locking. Once claimed (or sent), every future
   * call — including one made by a Cloud Tasks redelivery arriving after
   * a crash between the claim and `markNotificationSent`, or after an
   * ambiguous provider outcome — returns a non-`'claimed'` result and must
   * not call the provider again. This is deliberately permanent: nothing
   * ever resets a claim, by design (at-most-once, never a background
   * retry of the user-visible send). */
  async claimNotificationDispatch(
    operationId: string,
    atMs: number,
  ): Promise<NotificationDispatchClaim> {
    const ref = this.firestore.collection(RESULTS).doc(operationId);
    return this.firestore.runTransaction(async (tx) => {
      const current = parseResult((await tx.get(ref)).data());
      if (!current) return 'not_found';
      if (current.notificationSentAtMs != null) return 'already_sent';
      if (current.notificationDispatchClaimedAtMs != null) return 'already_claimed';
      tx.set(ref, { ...current, notificationDispatchClaimedAtMs: atMs });
      return 'claimed';
    });
  }
}

function parseResult(data: Record<string, unknown> | undefined): ReadingOperationResult | null {
  if (!data || data.schemaVersion !== 1) return null;
  if (typeof data.operationId !== 'string' || typeof data.ownerUserId !== 'string') return null;
  if (data.readingType !== 'coffee' && data.readingType !== 'palm' && data.readingType !== 'soulmate') return null;
  if (typeof data.resultId !== 'string' || !data.data || typeof data.data !== 'object') return null;
  if (typeof data.persistedAtMs !== 'number') return null;
  return {
    schemaVersion: 1,
    operationId: data.operationId,
    ownerUserId: data.ownerUserId,
    readingType: data.readingType,
    resultId: data.resultId,
    data: data.data as Record<string, unknown>,
    persistedAtMs: data.persistedAtMs,
    notificationSentAtMs:
      typeof data.notificationSentAtMs === 'number' ? data.notificationSentAtMs : null,
    notificationDispatchClaimedAtMs:
      typeof data.notificationDispatchClaimedAtMs === 'number'
        ? data.notificationDispatchClaimedAtMs
        : undefined,
    generationTrace: parseTrace(data.generationTrace),
  };
}

function parseTrace(value: unknown): ReadingGenerationTrace | undefined {
  if (!value || typeof value !== 'object') return undefined;
  const trace = value as Record<string, unknown>;
  return typeof trace.pipelineVersion === 'string' && typeof trace.interpretationContractVersion === 'string' &&
    typeof trace.promptRulesVersion === 'string' && typeof trace.modelIdentifier === 'string'
    ? trace as ReadingGenerationTrace : undefined;
}
