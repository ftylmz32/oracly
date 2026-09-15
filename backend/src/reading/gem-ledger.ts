/**
 * Durable gem ledger for acceleration spend and refund.
 * Local SharedPreferences balances are not consulted and are not authority.
 */
import { createHash, randomBytes } from 'node:crypto';
import type { FirestoreLike, FirestoreTransactionLike } from '../billing/entitlement-repository.js';
import type { ServerClock } from './clock.js';
import { toEpochMs } from './clock.js';
import {
  resolveAccelerationCost,
  type GemCostPolicy,
} from './gem-cost-policy.js';
import {
  isFailureCode,
  isOperationId,
  isReadingType,
  parseStoredRecord,
  toStoredDocument,
  type FailureCode,
  type ReadingOperationRecord,
  type ReadingType,
} from './operation-model.js';
import { ReadingStorageUnavailable } from './operation-repository.js';

const OPERATIONS = 'readingOperations';
const TRANSACTIONS = 'gemTransactions';
const KEYS = 'gemTransactionKeys';
const BALANCES = 'gemBalances';
const SCHEMA_VERSION = 1;

const IDEMPOTENCY = /^[A-Za-z0-9._:-]{8,64}$/;

export type GemTransactionType = 'earn' | 'spend' | 'refund';

export type GemTransactionRecord = {
  schemaVersion: typeof SCHEMA_VERSION;
  transactionId: string;
  ownerUserId: string;
  operationId: string | null;
  type: GemTransactionType;
  amount: number;
  reason: string;
  idempotencyKey: string;
  relatedTransactionId: string | null;
  createdAtMs: number;
  status: 'posted';
};

export type AccelerateOutcome =
  | 'accelerated'
  | 'already_accelerated'
  | 'already_ready'
  | 'already_eligible'
  | 'insufficient_gems'
  | 'price_changed';

export type AccelerateResult = {
  outcome: AccelerateOutcome;
  idempotent: boolean;
  operation: ReadingOperationRecord;
  balance: number;
  canonicalCost: number;
  priceToken: string;
};

/**
 * Opaque, stateless proof of "which price the user saw" -- not a secret,
 * not a discount channel (the server always recomputes cost itself and
 * only ever refuses on mismatch, never trusts a client-supplied amount).
 * Deterministic in (operationId, cost) so a quote and a later accelerate
 * call can agree without any new persisted state.
 */
export function priceTokenFor(operationId: string, cost: number): string {
  return createHash('sha256').update(`${operationId}:${cost}`).digest('hex').slice(0, 24);
}

export class GemLedgerError extends Error {
  constructor(
    readonly code:
      | 'not_found'
      | 'invalid'
      | 'conflict'
      | 'insufficient_gems'
      | 'already_ready'
      | 'already_accelerated'
      | 'unavailable',
  ) {
    super(code);
    this.name = 'GemLedgerError';
  }
}

export class GemLedger {
  constructor(
    private readonly firestore: FirestoreLike,
    private readonly clock: ServerClock,
    private readonly costs: GemCostPolicy,
  ) {}

  async balanceOf(ownerUserId: string): Promise<number> {
    const snap = await this.firestore
      .collection(BALANCES)
      .doc(documentIdFor(ownerUserId))
      .get();
    return readBalance(snap.data(), ownerUserId);
  }

  /**
   * Read-only preview of what /accelerate would charge for this operation.
   * No transaction, no write, no idempotency key consumed -- cannot affect
   * the ledger. Uses the exact same cost policy instance as the real
   * charge, so this can never drift from what accelerate() actually debits.
   */
  async quoteAcceleration(input: {
    ownerUserId: string;
    operationId: string;
  }): Promise<{ cost: number; balance: number; priceToken: string; payable: boolean } | null> {
    if (!isOperationId(input.operationId)) return null;
    const [opSnap, balanceSnap] = await Promise.all([
      this.firestore.collection(OPERATIONS).doc(input.operationId).get(),
      this.firestore.collection(BALANCES).doc(documentIdFor(input.ownerUserId)).get(),
    ]);
    const operation = parseStoredRecord(opSnap.data());
    if (!operation || operation.ownerUserId !== input.ownerUserId) return null;
    const cost = resolveAccelerationCost(operation.readingType, this.costs);
    // Once the free wait is already over, there is nothing left to sell --
    // the same boundary accelerate() itself enforces. A quote fetched after
    // that must never look actionable/payable to the client.
    const nowMs = toEpochMs(this.clock.now());
    return {
      cost,
      balance: readBalance(balanceSnap.data(), input.ownerUserId),
      priceToken: priceTokenFor(operation.operationId, cost),
      payable: operation.status === 'waiting' && nowMs < operation.readyAtMs,
    };
  }

  /** Internal credit. Not a client endpoint. Idempotent per owner + key. */
  async credit(input: {
    ownerUserId: string;
    amount: number;
    idempotencyKey: string;
    reason?: string;
  }): Promise<{ balance: number; transactionId: string; idempotent: boolean }> {
    if (!Number.isInteger(input.amount) || input.amount < 1 || input.amount > 10_000) {
      throw new GemLedgerError('invalid');
    }
    const key = parseIdempotency(input.idempotencyKey);
    if (!key) throw new GemLedgerError('invalid');
    const nowMs = toEpochMs(this.clock.now());
    try {
      return await this.firestore.runTransaction(async (tx) => {
        const keyRef = this.firestore.collection(KEYS).doc(keyDocId(input.ownerUserId, key));
        const keySnap = await tx.get(keyRef);
        if (keySnap.exists) {
          const existing = await this.readPosted(tx, keySnap.data()?.transactionId, input.ownerUserId);
          const balance = await this.readBalanceTx(tx, input.ownerUserId);
          return { balance, transactionId: existing.transactionId, idempotent: true };
        }
        const balanceRef = this.firestore.collection(BALANCES).doc(documentIdFor(input.ownerUserId));
        const balanceSnap = await tx.get(balanceRef);
        const balance = readBalance(balanceSnap.data(), input.ownerUserId);
        const next = balance + input.amount;
        const transactionId = randomBytes(16).toString('hex');
        const record = posted({
          transactionId,
          ownerUserId: input.ownerUserId,
          operationId: null,
          type: 'earn',
          amount: input.amount,
          reason: input.reason ?? 'internal_credit',
          idempotencyKey: key,
          relatedTransactionId: null,
          createdAtMs: nowMs,
        });
        tx.set(this.firestore.collection(TRANSACTIONS).doc(transactionId), record);
        tx.set(keyRef, { transactionId, ownerUserId: input.ownerUserId });
        tx.set(balanceRef, {
          schemaVersion: SCHEMA_VERSION,
          ownerUserId: input.ownerUserId,
          balance: next,
          updatedAtMs: nowMs,
        });
        return { balance: next, transactionId, idempotent: false };
      });
    } catch (error) {
      throw mapStorage(error);
    }
  }

  /** Internal server-resolved debit. No public API accepts an amount. */
  async debit(input: {
    ownerUserId: string;
    amount: number;
    idempotencyKey: string;
    operationId: string;
    reason: string;
  }): Promise<{ balance: number; transactionId: string; idempotent: boolean }> {
    if (!Number.isInteger(input.amount) || input.amount < 1 || input.amount > 10_000) {
      throw new GemLedgerError('invalid');
    }
    const key = parseIdempotency(input.idempotencyKey);
    if (!key || !isPurposeOperationId(input.operationId) || input.reason.length < 3) {
      throw new GemLedgerError('invalid');
    }
    const nowMs = toEpochMs(this.clock.now());
    try {
      return await this.firestore.runTransaction(async (tx) => {
        const keyRef = this.firestore.collection(KEYS).doc(keyDocId(input.ownerUserId, key));
        const keySnap = await tx.get(keyRef);
        const balanceRef = this.firestore.collection(BALANCES).doc(documentIdFor(input.ownerUserId));
        const balanceSnap = await tx.get(balanceRef);
        const balance = readBalance(balanceSnap.data(), input.ownerUserId);
        if (keySnap.exists) {
          const existing = await this.readPosted(tx, keySnap.data()?.transactionId, input.ownerUserId);
          if (existing.type !== 'spend' || existing.operationId !== input.operationId) {
            throw new GemLedgerError('conflict');
          }
          return { balance, transactionId: existing.transactionId, idempotent: true };
        }
        if (balance < input.amount) throw new GemLedgerError('insufficient_gems');
        const transactionId = randomBytes(16).toString('hex');
        const nextBalance = balance - input.amount;
        const record = posted({
          transactionId,
          ownerUserId: input.ownerUserId,
          operationId: input.operationId,
          type: 'spend',
          amount: input.amount,
          reason: input.reason,
          idempotencyKey: key,
          relatedTransactionId: null,
          createdAtMs: nowMs,
        });
        tx.set(this.firestore.collection(TRANSACTIONS).doc(transactionId), record);
        tx.set(keyRef, { transactionId, ownerUserId: input.ownerUserId, operationId: input.operationId });
        tx.set(balanceRef, {
          schemaVersion: SCHEMA_VERSION,
          ownerUserId: input.ownerUserId,
          balance: nextBalance,
          updatedAtMs: nowMs,
        });
        return { balance: nextBalance, transactionId, idempotent: false };
      });
    } catch (error) {
      throw mapStorage(error);
    }
  }

  async accelerate(input: {
    ownerUserId: string;
    operationId: string;
    idempotencyKey: string;
    /**
     * Echo of the priceToken the user's quote showed, not a client-chosen
     * amount. Optional for backward compatibility with older callers -- when
     * omitted, behavior is unchanged (charges the current canonical cost).
     * When present and stale, this is the ONLY effect: no debit happens and
     * `price_changed` is returned instead, carrying the fresh cost/token so
     * the caller can requote and require a new explicit user tap.
     */
    expectedPriceToken?: string;
  }): Promise<AccelerateResult> {
    if (!isOperationId(input.operationId)) throw new GemLedgerError('not_found');
    const key = parseIdempotency(input.idempotencyKey);
    if (!key) throw new GemLedgerError('invalid');
    const nowMs = toEpochMs(this.clock.now());
    try {
      return await this.firestore.runTransaction(async (tx) => {
        const opRef = this.firestore.collection(OPERATIONS).doc(input.operationId);
        const keyRef = this.firestore.collection(KEYS).doc(keyDocId(input.ownerUserId, key));
        const balanceRef = this.firestore.collection(BALANCES).doc(documentIdFor(input.ownerUserId));
        const opSnap = await tx.get(opRef);
        const keySnap = await tx.get(keyRef);
        const balanceSnap = await tx.get(balanceRef);
        const operation = parseStoredRecord(opSnap.data());
        if (!operation || operation.ownerUserId !== input.ownerUserId) {
          throw new GemLedgerError('not_found');
        }
        const balance = readBalance(balanceSnap.data(), input.ownerUserId);
        const cost = resolveAccelerationCost(operation.readingType, this.costs);
        const priceToken = priceTokenFor(operation.operationId, cost);
        if (keySnap.exists) {
          const existingId = keySnap.data()?.transactionId;
          const existing = await this.readPosted(tx, existingId, input.ownerUserId);
          if (existing.operationId !== operation.operationId || existing.type !== 'spend') {
            throw new GemLedgerError('conflict');
          }
          return {
            outcome: 'accelerated' as const,
            idempotent: true,
            operation,
            balance,
            canonicalCost: cost,
            priceToken,
          };
        }
        if (operation.status === 'ready' || operation.resultId) {
          return {
            outcome: 'already_ready' as const,
            idempotent: false,
            operation,
            balance,
            canonicalCost: cost,
            priceToken,
          };
        }
        if (operation.status === 'failed') {
          throw new GemLedgerError('conflict');
        }
        if (isAccelerated(operation)) {
          return {
            outcome: 'already_accelerated' as const,
            idempotent: false,
            operation,
            balance,
            canonicalCost: cost,
            priceToken,
          };
        }
        if (operation.status !== 'waiting' || !isReadingType(operation.readingType)) {
          throw new GemLedgerError('conflict');
        }
        // The free wait is already over -- there is nothing left to sell.
        // Cloud Tasks queue/claim latency is infrastructure delay, not
        // remaining wait time; charging here would bill the user for time
        // they already waited out. Zero debit, no ledger write at all. The
        // operation stays exactly as it is -- already eligible, already
        // durably scheduled from when it was staged/accelerated-free -- and
        // the caller reconciles via its normal waiting/processing/ready
        // observation, same as any other still-`waiting` snapshot.
        if (nowMs >= operation.readyAtMs) {
          return {
            outcome: 'already_eligible' as const,
            idempotent: false,
            operation,
            balance,
            canonicalCost: cost,
            priceToken,
          };
        }
        // Price confirmation -- not authority. The server still computed
        // `cost` itself above; a mismatch just means the deployed policy
        // moved since the user's quote, so we refuse to charge silently
        // and hand back the fresh price instead of debiting anything.
        if (input.expectedPriceToken != null && input.expectedPriceToken !== priceToken) {
          return {
            outcome: 'price_changed' as const,
            idempotent: false,
            operation,
            balance,
            canonicalCost: cost,
            priceToken,
          };
        }
        if (balance < cost) {
          throw new GemLedgerError('insufficient_gems');
        }
        const transactionId = randomBytes(16).toString('hex');
        const nextBalance = balance - cost;
        const spend = posted({
          transactionId,
          ownerUserId: input.ownerUserId,
          operationId: operation.operationId,
          type: 'spend',
          amount: cost,
          reason: 'acceleration',
          idempotencyKey: key,
          relatedTransactionId: null,
          createdAtMs: nowMs,
        });
        const nextOp: ReadingOperationRecord = {
          ...operation,
          status: 'processing',
          acceleratedAtMs: nowMs,
          gemDebitId: transactionId,
          updatedAtMs: nowMs,
        };
        tx.set(this.firestore.collection(TRANSACTIONS).doc(transactionId), {
          ...spend,
          refundTransactionId: null,
        });
        tx.set(keyRef, {
          transactionId,
          ownerUserId: input.ownerUserId,
          operationId: operation.operationId,
        });
        tx.set(balanceRef, {
          schemaVersion: SCHEMA_VERSION,
          ownerUserId: input.ownerUserId,
          balance: nextBalance,
          updatedAtMs: nowMs,
        });
        tx.set(opRef, toStoredDocument(nextOp));
        return {
          outcome: 'accelerated' as const,
          idempotent: false,
          operation: nextOp,
          balance: nextBalance,
          canonicalCost: cost,
          priceToken,
        };
      });
    } catch (error) {
      throw mapStorage(error);
    }
  }

  /**
   * Refund the original acceleration spend exactly once after final failure.
   * A ready result cannot be refunded. Client amount is never accepted.
   */
  async refundFailedAcceleration(input: {
    ownerUserId: string;
    operationId: string;
    failureCode?: FailureCode;
  }): Promise<{
    operation: ReadingOperationRecord;
    balance: number;
    refundTransactionId: string;
    spendTransactionId: string;
    idempotent: boolean;
  }> {
    if (!isOperationId(input.operationId)) throw new GemLedgerError('not_found');
    const failureCode = input.failureCode ?? 'unavailable';
    if (!isFailureCode(failureCode)) throw new GemLedgerError('invalid');
    const nowMs = toEpochMs(this.clock.now());
    try {
      return await this.firestore.runTransaction(async (tx) => {
        const opRef = this.firestore.collection(OPERATIONS).doc(input.operationId);
        const opSnap = await tx.get(opRef);
        const operation = parseStoredRecord(opSnap.data());
        if (!operation || operation.ownerUserId !== input.ownerUserId) {
          throw new GemLedgerError('not_found');
        }
        if (operation.status === 'ready' || operation.resultId) {
          throw new GemLedgerError('conflict');
        }
        if (!operation.gemDebitId || !operation.acceleratedAtMs) {
          throw new GemLedgerError('conflict');
        }
        const spendRef = this.firestore.collection(TRANSACTIONS).doc(operation.gemDebitId);
        const spendSnap = await tx.get(spendRef);
        const spend = parseTransaction(spendSnap.data());
        if (
          !spend ||
          spend.ownerUserId !== input.ownerUserId ||
          spend.type !== 'spend' ||
          spend.operationId !== operation.operationId
        ) {
          throw new GemLedgerError('conflict');
        }
        const existingRefundId = refundIdOf(spendSnap.data());
        if (existingRefundId) {
          const refund = await this.readPosted(tx, existingRefundId, input.ownerUserId);
          const balance = await this.readBalanceTx(tx, input.ownerUserId);
          return {
            operation: failedCopy(operation, failureCode, nowMs),
            balance,
            refundTransactionId: refund.transactionId,
            spendTransactionId: spend.transactionId,
            idempotent: true,
          };
        }
        const balanceRef = this.firestore.collection(BALANCES).doc(documentIdFor(input.ownerUserId));
        const balanceSnap = await tx.get(balanceRef);
        const balance = readBalance(balanceSnap.data(), input.ownerUserId);
        const refundTransactionId = randomBytes(16).toString('hex');
        const refund = posted({
          transactionId: refundTransactionId,
          ownerUserId: input.ownerUserId,
          operationId: operation.operationId,
          type: 'refund',
          amount: spend.amount,
          reason: 'acceleration_refund',
          idempotencyKey: `refund:${spend.transactionId}`,
          relatedTransactionId: spend.transactionId,
          createdAtMs: nowMs,
        });
        const nextBalance = balance + spend.amount;
        const nextOp = failedCopy(operation, failureCode, nowMs);
        tx.set(this.firestore.collection(TRANSACTIONS).doc(refundTransactionId), refund);
        tx.set(spendRef, {
          ...toTransactionDoc(spend),
          refundTransactionId,
        });
        tx.set(balanceRef, {
          schemaVersion: SCHEMA_VERSION,
          ownerUserId: input.ownerUserId,
          balance: nextBalance,
          updatedAtMs: nowMs,
        });
        tx.set(opRef, toStoredDocument(nextOp));
        return {
          operation: nextOp,
          balance: nextBalance,
          refundTransactionId,
          spendTransactionId: spend.transactionId,
          idempotent: false,
        };
      });
    } catch (error) {
      throw mapStorage(error);
    }
  }

  async trace(ownerUserId: string, operationId: string): Promise<{
    spend: GemTransactionRecord | null;
    refund: GemTransactionRecord | null;
  }> {
    if (!isOperationId(operationId)) throw new GemLedgerError('not_found');
    const opSnap = await this.firestore.collection(OPERATIONS).doc(operationId).get();
    const operation = parseStoredRecord(opSnap.data());
    if (!operation || operation.ownerUserId !== ownerUserId || !operation.gemDebitId) {
      return { spend: null, refund: null };
    }
    const spendSnap = await this.firestore.collection(TRANSACTIONS).doc(operation.gemDebitId).get();
    const spend = parseTransaction(spendSnap.data());
    if (!spend || spend.ownerUserId !== ownerUserId) return { spend: null, refund: null };
    const refundId = refundIdOf(spendSnap.data());
    if (!refundId) return { spend, refund: null };
    const refundSnap = await this.firestore.collection(TRANSACTIONS).doc(refundId).get();
    const refund = parseTransaction(refundSnap.data());
    return { spend, refund: refund && refund.ownerUserId === ownerUserId ? refund : null };
  }

  private async readPosted(
    tx: FirestoreTransactionLike,
    transactionId: unknown,
    ownerUserId: string,
  ): Promise<GemTransactionRecord> {
    if (typeof transactionId !== 'string' || !isOperationId(transactionId)) {
      throw new GemLedgerError('conflict');
    }
    const snap = await tx.get(this.firestore.collection(TRANSACTIONS).doc(transactionId));
    const parsed = parseTransaction(snap.data());
    if (!parsed || parsed.ownerUserId !== ownerUserId) {
      throw new GemLedgerError('conflict');
    }
    return parsed;
  }

  private async readBalanceTx(
    tx: FirestoreTransactionLike,
    ownerUserId: string,
  ): Promise<number> {
    const snap = await tx.get(
      this.firestore.collection(BALANCES).doc(documentIdFor(ownerUserId)),
    );
    return readBalance(snap.data(), ownerUserId);
  }
}

function isAccelerated(operation: ReadingOperationRecord): boolean {
  return (
    operation.acceleratedAtMs != null ||
    operation.gemDebitId != null ||
    operation.status === 'processing'
  );
}

function isPurposeOperationId(value: string): boolean {
  return /^[A-Za-z0-9._:-]{8,128}$/.test(value);
}

function failedCopy(
  operation: ReadingOperationRecord,
  failureCode: FailureCode,
  nowMs: number,
): ReadingOperationRecord {
  if (operation.status === 'failed') return operation;
  return {
    ...operation,
    status: 'failed',
    failureCode,
    updatedAtMs: nowMs,
  };
}

function posted(input: Omit<GemTransactionRecord, 'schemaVersion' | 'status'>): GemTransactionRecord {
  return { schemaVersion: SCHEMA_VERSION, status: 'posted', ...input };
}

function toTransactionDoc(record: GemTransactionRecord): Record<string, unknown> {
  return { ...record };
}

function parseTransaction(data: Record<string, unknown> | undefined): GemTransactionRecord | null {
  if (!data || data.schemaVersion !== SCHEMA_VERSION) return null;
  if (typeof data.transactionId !== 'string' || !isOperationId(data.transactionId)) return null;
  if (typeof data.ownerUserId !== 'string' || data.ownerUserId.length < 4) return null;
  if (data.type !== 'earn' && data.type !== 'spend' && data.type !== 'refund') return null;
  if (!Number.isInteger(data.amount) || (data.amount as number) < 1) return null;
  if (typeof data.reason !== 'string' || data.reason.length < 3) return null;
  if (typeof data.idempotencyKey !== 'string') return null;
  if (data.status !== 'posted') return null;
  if (!Number.isFinite(data.createdAtMs)) return null;
  const operationId = data.operationId == null ? null : data.operationId;
  if (operationId != null && typeof operationId !== 'string') return null;
  const related = data.relatedTransactionId == null ? null : data.relatedTransactionId;
  if (related != null && typeof related !== 'string') return null;
  return {
    schemaVersion: SCHEMA_VERSION,
    transactionId: data.transactionId,
    ownerUserId: data.ownerUserId,
    operationId,
    type: data.type,
    amount: data.amount as number,
    reason: data.reason,
    idempotencyKey: data.idempotencyKey,
    relatedTransactionId: related,
    createdAtMs: data.createdAtMs as number,
    status: 'posted',
  };
}

function readBalance(data: Record<string, unknown> | undefined, ownerUserId: string): number {
  if (!data) return 0;
  if (data.ownerUserId !== ownerUserId) return 0;
  const balance = data.balance;
  if (typeof balance !== 'number' || !Number.isInteger(balance) || balance < 0) return 0;
  return balance;
}

function refundIdOf(data: Record<string, unknown> | undefined): string | null {
  const value = data?.refundTransactionId;
  return typeof value === 'string' && value.length > 0 ? value : null;
}

export function parseIdempotency(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return IDEMPOTENCY.test(trimmed) ? trimmed : null;
}

function keyDocId(ownerUserId: string, idempotencyKey: string): string {
  return documentIdFor(`${ownerUserId}\0${idempotencyKey}`);
}

function documentIdFor(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}

function mapStorage(error: unknown): Error {
  if (error instanceof GemLedgerError) return error;
  if (error instanceof ReadingStorageUnavailable) return new GemLedgerError('unavailable');
  return new GemLedgerError('unavailable');
}

export function canonicalCostFor(
  type: ReadingType,
  policy: GemCostPolicy,
): number {
  return resolveAccelerationCost(type, policy);
}
