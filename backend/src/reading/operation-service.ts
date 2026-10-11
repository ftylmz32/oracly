/**
 * Authoritative reading-operation lifecycle.
 * Create and status are public. Result attachment and failure are internal.
 * No gem debit and no AI execution happen here.
 */
import { randomBytes } from 'node:crypto';
import type { ServerClock } from './clock.js';
import { toEpochMs } from './clock.js';
import {
  isFailureCode,
  isOperationId,
  parseResultId,
  type ExecutionMode,
  type CoffeeInputContract,
  COFFEE_V3_CAPTURE_CONTRACT,
  type CoffeeCaptureContract,
  type FailureCode,
  type ReadingOperationRecord, type ReadingLanguage,
  type ReadingType,
  SCHEMA_VERSION,
} from './operation-model.js';
import {
  idempotencyKeyFor,
  ReadingStorageUnavailable,
  type ReadingOperationRepository,
} from './operation-repository.js';
import {
  resolveWaitMs,
  type WaitPolicy,
} from './wait-policy.js';
import { ReadingAdmissionDenied } from './reading-admission.js';
import { sanitizeCoffeeIntention } from './coffee-intention.js';

export type ServiceErrorCode =
  | 'not_found'
  | 'forbidden'
  | 'conflict'
  | 'invalid'
  | 'rate_limited'
  | 'unavailable';

export class ReadingOperationError extends Error {
  constructor(readonly code: ServiceErrorCode, cause?: unknown) {
    super(code, cause instanceof Error ? { cause } : undefined);
    this.name = 'ReadingOperationError';
  }
}

export class ReadingOperationService {
  constructor(
    private readonly repository: ReadingOperationRepository,
    private readonly clock: ServerClock,
    private readonly policy: WaitPolicy,
    private readonly newOperationId: () => string = randomOperationId,
  ) {}

  async create(input: {
    ownerUserId: string;
    readingType: ReadingType;
    sourceRequestId: string;
    language?: ReadingLanguage;
    executionMode?: ExecutionMode;
    coffeeIntention?: string;
    coffeeInputContract?: CoffeeInputContract;
    /** LIS1 — dark: not accepted by the public create route yet. */
    coffeeCaptureContract?: CoffeeCaptureContract;
  }): Promise<ReadingOperationRecord> {
    const markedCoffee = input.readingType === 'coffee' && input.coffeeInputContract != null;
    const coffeeIntention = markedCoffee && input.coffeeIntention != null
      ? sanitizeCoffeeIntention(input.coffeeIntention)
      : null;
    if ((input.coffeeInputContract != null || input.coffeeIntention != null) &&
        (!markedCoffee || !coffeeIntention)) {
      throw new ReadingOperationError('invalid');
    }
    // A three-view V3 operation is Coffee only and always carries the trusted
    // intention contract (no second intention contract exists). The retired
    // four-view contract can never be created again.
    const coffeeCaptureContract = input.coffeeCaptureContract ?? null;
    if (coffeeCaptureContract != null &&
        (coffeeCaptureContract !== COFFEE_V3_CAPTURE_CONTRACT ||
          input.readingType !== 'coffee' || input.coffeeInputContract !== 'trusted_intention_v1' || !coffeeIntention)) {
      throw new ReadingOperationError('invalid');
    }
    const nowMs = toEpochMs(this.clock.now());
    const readyAtMs = nowMs + resolveWaitMs(input.readingType, this.policy);
    const record: ReadingOperationRecord = {
      schemaVersion: SCHEMA_VERSION,
      operationId: this.newOperationId(),
      ownerUserId: input.ownerUserId,
      readingType: input.readingType,
      language: input.language ?? 'tr',
      status: 'waiting',
      createdAtMs: nowMs,
      readyAtMs,
      updatedAtMs: nowMs,
      sourceRequestId: input.sourceRequestId,
      resultId: null,
      failureCode: null,
      acceleratedAtMs: null,
      gemDebitId: null,
      executionStartedAtMs: null,
      executionMode: input.executionMode ?? null,
      coffeeIntention,
      coffeeInputContract: markedCoffee ? input.coffeeInputContract! : null,
      coffeeCaptureContract,
    };
    try {
      const stored = await this.repository.createIfAbsent(
        record,
        idempotencyKeyFor(input),
      );
      if (stored.record.ownerUserId !== input.ownerUserId) {
        throw new ReadingOperationError('forbidden');
      }
      if (
        input.readingType === 'coffee' &&
        (stored.record.coffeeIntention !== coffeeIntention ||
          stored.record.coffeeInputContract !== (markedCoffee ? input.coffeeInputContract! : null) ||
          // Same sourceRequestId = same logical create: the photo-set contract must match too.
          stored.record.coffeeCaptureContract !== coffeeCaptureContract)
      ) {
        throw new ReadingOperationError('conflict');
      }
      return stored.record;
    } catch (error) {
      if (error instanceof ReadingOperationError) throw error;
      if (error instanceof ReadingAdmissionDenied) {
        throw new ReadingOperationError('rate_limited', error);
      }
      if (error instanceof ReadingStorageUnavailable) {
        throw new ReadingOperationError('unavailable');
      }
      throw new ReadingOperationError('unavailable');
    }
  }

  async get(
    ownerUserId: string,
    operationId: string,
  ): Promise<ReadingOperationRecord> {
    if (!isOperationId(operationId)) {
      throw new ReadingOperationError('not_found');
    }
    const record = await this.readOwned(ownerUserId, operationId);
    return record;
  }

  /**
   * Internal. A result may attach once. Wait elapsed is not enough.
   * Same resultId is idempotent. A second result is rejected.
   */
  async attachResult(input: {
    ownerUserId: string;
    operationId: string;
    resultId: string;
  }): Promise<ReadingOperationRecord> {
    const resultId = parseResultId(input.resultId);
    if (!resultId) throw new ReadingOperationError('invalid');
    const updatedAtMs = toEpochMs(this.clock.now());
    return this.mutateOwned(input.ownerUserId, input.operationId, (current) => {
      if (current.status === 'ready') {
        if (current.resultId === resultId) return current;
        throw new ReadingOperationError('conflict');
      }
      if (current.status === 'failed') {
        throw new ReadingOperationError('conflict');
      }
      if (current.status !== 'waiting' && current.status !== 'processing') {
        throw new ReadingOperationError('conflict');
      }
      return {
        ...current,
        status: 'ready',
        resultId,
        failureCode: null,
        updatedAtMs,
      };
    });
  }

  /**
   * Internal. A ready operation cannot be downgraded by a stale failure.
   * Repeating the same failure code is idempotent.
   */
  async fail(input: {
    ownerUserId: string;
    operationId: string;
    failureCode: FailureCode;
  }): Promise<ReadingOperationRecord> {
    if (!isFailureCode(input.failureCode)) {
      throw new ReadingOperationError('invalid');
    }
    const updatedAtMs = toEpochMs(this.clock.now());
    return this.mutateOwned(input.ownerUserId, input.operationId, (current) => {
      if (current.status === 'ready') {
        throw new ReadingOperationError('conflict');
      }
      if (current.status === 'failed') {
        if (current.failureCode === input.failureCode) return current;
        throw new ReadingOperationError('conflict');
      }
      return {
        ...current,
        status: 'failed',
        failureCode: input.failureCode,
        updatedAtMs,
      };
    });
  }

  private async readOwned(
    ownerUserId: string,
    operationId: string,
  ): Promise<ReadingOperationRecord> {
    let record: ReadingOperationRecord | null;
    try {
      record = await this.repository.getById(operationId);
    } catch (error) {
      if (error instanceof ReadingStorageUnavailable) {
        throw new ReadingOperationError('unavailable');
      }
      throw new ReadingOperationError('unavailable');
    }
    if (!record || record.ownerUserId !== ownerUserId) {
      throw new ReadingOperationError('not_found');
    }
    return record;
  }

  private async mutateOwned(
    ownerUserId: string,
    operationId: string,
    apply: (current: ReadingOperationRecord) => ReadingOperationRecord,
  ): Promise<ReadingOperationRecord> {
    if (!isOperationId(operationId)) {
      throw new ReadingOperationError('not_found');
    }
    try {
      return await this.repository.mutate(operationId, ownerUserId, apply);
    } catch (error) {
      if (error instanceof ReadingOperationError) throw error;
      if (error instanceof ReadingStorageUnavailable) {
        throw new ReadingOperationError('not_found');
      }
      throw new ReadingOperationError('unavailable');
    }
  }
}

export function randomOperationId(): string {
  return randomBytes(16).toString('hex');
}
