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
    /** Commerce creates are eligible at once. Absent keeps the wait policy. */
    instant?: boolean;
    /** When set, a different returned id means an older operation won idempotency. */
    operationId?: string;
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
    if (input.operationId != null && !isOperationId(input.operationId)) {
      throw new ReadingOperationError('invalid');
    }
    const nowMs = toEpochMs(this.clock.now());
    const readyAtMs = nowMs + (input.instant ? 0 : resolveWaitMs(input.readingType, this.policy));
    const record: ReadingOperationRecord = {
      schemaVersion: SCHEMA_VERSION,
      operationId: input.operationId ?? this.newOperationId(),
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
      return sameCreateOrThrow(stored.record, input, {
        coffeeIntention,
        coffeeInputContract: markedCoffee ? input.coffeeInputContract! : null,
        coffeeCaptureContract,
      });
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

  /**
   * Read-only twin of an idempotent `create` retry: the operation an earlier
   * create stored for this owner + type + sourceRequestId, under the same
   * owner and contract checks, or null. Never creates, never writes.
   */
  async findCreated(input: {
    ownerUserId: string;
    readingType: ReadingType;
    sourceRequestId: string;
    coffeeIntention?: string;
    coffeeInputContract?: CoffeeInputContract;
    coffeeCaptureContract?: CoffeeCaptureContract;
  }): Promise<ReadingOperationRecord | null> {
    if (!this.repository.findByIdempotencyKey) return null;
    let stored: ReadingOperationRecord | null;
    try {
      stored = await this.repository.findByIdempotencyKey(idempotencyKeyFor(input));
    } catch {
      throw new ReadingOperationError('unavailable');
    }
    if (!stored) return null;
    const markedCoffee = input.readingType === 'coffee' && input.coffeeInputContract != null;
    return sameCreateOrThrow(stored, input, {
      coffeeIntention: markedCoffee && input.coffeeIntention != null
        ? sanitizeCoffeeIntention(input.coffeeIntention)
        : null,
      coffeeInputContract: markedCoffee ? input.coffeeInputContract! : null,
      coffeeCaptureContract: input.coffeeCaptureContract ?? null,
    });
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

/** An idempotent create retry is the same owner and, for Coffee, the same contract. */
function sameCreateOrThrow(
  stored: ReadingOperationRecord,
  input: { ownerUserId: string; readingType: ReadingType },
  coffee: {
    coffeeIntention: string | null;
    coffeeInputContract: CoffeeInputContract | null;
    coffeeCaptureContract: CoffeeCaptureContract | null;
  },
): ReadingOperationRecord {
  if (stored.ownerUserId !== input.ownerUserId) {
    throw new ReadingOperationError('forbidden');
  }
  if (
    input.readingType === 'coffee' &&
    (stored.coffeeIntention !== coffee.coffeeIntention ||
      stored.coffeeInputContract !== coffee.coffeeInputContract ||
      // Same sourceRequestId = same logical create: the photo-set contract must match too.
      stored.coffeeCaptureContract !== coffee.coffeeCaptureContract)
  ) {
    throw new ReadingOperationError('conflict');
  }
  return stored;
}
