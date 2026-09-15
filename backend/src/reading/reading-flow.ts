/**
 * Shared lifecycle for Coffee / Palm / Soulmate.
 * Feature pipelines stay outside. This layer only claims, completes, and recovers.
 */
import { createHash } from 'node:crypto';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import type { ServerClock } from './clock.js';
import { toEpochMs } from './clock.js';
import { GemLedger, GemLedgerError } from './gem-ledger.js';
import {
  isFailureCode,
  isOperationId,
  isReadingType,
  parseResultId,
  parseStoredRecord,
  toStoredDocument,
  type FailureCode,
  type ReadingOperationRecord,
  type ReadingType,
} from './operation-model.js';
import { ReadingOperationError, type ReadingOperationService } from './operation-service.js';

const OPERATIONS = 'readingOperations';
const ACTIVE = 'readingOperationActive';

/** Same logical operation may resume after a dropped client, not start a second one. */
export const PROCESSING_LEASE_MS = 12 * 60 * 1000;

export type ClaimResult = {
  execute: boolean;
  operation: ReadingOperationRecord;
};

export class ReadingFlow {
  constructor(
    private readonly firestore: FirestoreLike,
    private readonly clock: ServerClock,
    private readonly operations: ReadingOperationService,
    private readonly ledger: GemLedger | null,
  ) {}

  async remember(record: ReadingOperationRecord): Promise<void> {
    if (record.status !== 'waiting' && record.status !== 'processing') return;
    const ref = this.firestore.collection(ACTIVE).doc(activeId(record.ownerUserId, record.readingType));
    await this.firestore.runTransaction(async (tx) => {
      tx.set(ref, {
        operationId: record.operationId,
        ownerUserId: record.ownerUserId,
        readingType: record.readingType,
      });
    });
  }

  async active(
    ownerUserId: string,
    readingType: ReadingType,
  ): Promise<ReadingOperationRecord | null> {
    const snap = await this.firestore
      .collection(ACTIVE)
      .doc(activeId(ownerUserId, readingType))
      .get();
    const operationId = snap.data()?.operationId;
    if (typeof operationId !== 'string' || !isOperationId(operationId)) return null;
    return this.operations.get(ownerUserId, operationId);
  }

  async claim(ownerUserId: string, operationId: string): Promise<ClaimResult> {
    const nowMs = toEpochMs(this.clock.now());
    const operation = await this.mutate(ownerUserId, operationId, (current) => {
      if (current.status === 'ready' || current.status === 'failed') {
        return { record: current, execute: false };
      }
      const eligible =
        nowMs >= current.readyAtMs || current.acceleratedAtMs != null;
      if (current.status === 'waiting') {
        if (!eligible) return { record: current, execute: false };
        return {
          execute: true,
          record: {
            ...current,
            status: 'processing',
            executionStartedAtMs: nowMs,
            updatedAtMs: nowMs,
          },
        };
      }
      if (current.status !== 'processing') {
        return { record: current, execute: false };
      }
      if (current.resultId) return { record: current, execute: false };
      const started = current.executionStartedAtMs;
      if (started != null && nowMs - started < PROCESSING_LEASE_MS) {
        return { record: current, execute: false };
      }
      return {
        execute: true,
        record: {
          ...current,
          executionStartedAtMs: nowMs,
          updatedAtMs: nowMs,
        },
      };
    });
    return operation;
  }

  /**
   * After a retryable post-claim failure, expire the processing lease so
   * Cloud Tasks redelivery can reclaim the SAME operation immediately
   * instead of burning retries against an active lease window.
   */
  async releaseClaim(ownerUserId: string, operationId: string): Promise<void> {
    const nowMs = toEpochMs(this.clock.now());
    await this.mutate(ownerUserId, operationId, (current) => {
      if (current.status !== 'processing' || current.resultId) {
        return { record: current, execute: false };
      }
      return {
        execute: true,
        record: {
          ...current,
          executionStartedAtMs: nowMs - PROCESSING_LEASE_MS - 1,
          updatedAtMs: nowMs,
        },
      };
    });
  }

  async complete(input: {
    ownerUserId: string;
    operationId: string;
    resultId: string;
  }): Promise<ReadingOperationRecord> {
    const resultId = parseResultId(input.resultId);
    if (!resultId) throw new ReadingOperationError('invalid');
    const current = await this.operations.get(input.ownerUserId, input.operationId);
    if (current.status === 'waiting') throw new ReadingOperationError('conflict');
    return this.operations.attachResult({
      ownerUserId: input.ownerUserId,
      operationId: input.operationId,
      resultId,
    });
  }

  async failFinal(input: {
    ownerUserId: string;
    operationId: string;
    failureCode?: FailureCode;
  }): Promise<ReadingOperationRecord> {
    const failureCode = input.failureCode ?? 'unavailable';
    if (!isFailureCode(failureCode)) throw new ReadingOperationError('invalid');
    const current = await this.operations.get(input.ownerUserId, input.operationId);
    if (current.status === 'ready') throw new ReadingOperationError('conflict');
    if (current.gemDebitId && this.ledger) {
      try {
        const refunded = await this.ledger.refundFailedAcceleration({
          ownerUserId: input.ownerUserId,
          operationId: input.operationId,
          failureCode,
        });
        return refunded.operation;
      } catch (error) {
        if (error instanceof GemLedgerError && error.code === 'conflict') {
          return this.operations.get(input.ownerUserId, input.operationId);
        }
        throw new ReadingOperationError('unavailable');
      }
    }
    return this.operations.fail({
      ownerUserId: input.ownerUserId,
      operationId: input.operationId,
      failureCode,
    });
  }

  private async mutate(
    ownerUserId: string,
    operationId: string,
    apply: (
      current: ReadingOperationRecord,
    ) => { record: ReadingOperationRecord; execute: boolean },
  ): Promise<ClaimResult> {
    if (!isOperationId(operationId)) throw new ReadingOperationError('not_found');
    const ref = this.firestore.collection(OPERATIONS).doc(operationId);
    try {
      return await this.firestore.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        const current = parseStoredRecord(snap.data());
        if (!current || current.ownerUserId !== ownerUserId) {
          throw new ReadingOperationError('not_found');
        }
        const next = apply(current);
        if (next.execute) tx.set(ref, toStoredDocument(next.record));
        return { execute: next.execute, operation: next.record };
      });
    } catch (error) {
      if (error instanceof ReadingOperationError) throw error;
      throw new ReadingOperationError('unavailable');
    }
  }
}

export function activeId(ownerUserId: string, readingType: ReadingType): string {
  return createHash('sha256').update(`${ownerUserId}\0${readingType}`).digest('hex');
}

export function parseReadingTypeQuery(value: unknown): ReadingType | null {
  return isReadingType(value) ? value : null;
}
