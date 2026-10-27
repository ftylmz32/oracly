/**
 * New Coffee V3 and Palm operations spend one server credit and skip the
 * artificial wait. With commerce on, no other new Coffee exists: legacy and
 * Coffee V2 creates only find an operation made before the rollout. Soulmate
 * and every create while commerce is off stay on the existing wait policy.
 * A client price cannot open this.
 */
import { randomBytes } from 'node:crypto';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, type ErrorCodeName } from '../errors.js';
import type { ReadingCommerceFeature } from './reading-commerce-catalog.js';
import { ReadingEntitlementLedger } from './reading-entitlement-ledger.js';
import type {
  CoffeeCaptureContract,
  CoffeeInputContract,
  ExecutionMode,
  ReadingLanguage,
  ReadingOperationRecord,
  ReadingType,
} from './operation-model.js';
import { ReadingOperationError, type ReadingOperationService } from './operation-service.js';
import { ritualOperationId } from './ritual-daily-quota.js';

const SPEND_DAYS = 'aiSpendDays';
/** Server-only: the one request key a pre-rollout Palm operation may be read under. */
const LEGACY_DIRECT_AI = 'readingLegacyDirectAi';

export type CommerceCreateInput = {
  readingType: ReadingType;
  sourceRequestId: string;
  language: ReadingLanguage;
  executionMode?: ExecutionMode;
  coffeeIntention?: string;
  coffeeInputContract?: CoffeeInputContract;
  coffeeCaptureContract?: CoffeeCaptureContract;
};

export function commerceApplies(enabled: boolean, input: CommerceCreateInput): boolean {
  if (!enabled) return false;
  if (input.readingType === 'palm') return true;
  return input.readingType === 'coffee' && input.coffeeCaptureContract === 'three_view_v3';
}

/** Commerce on: a Coffee create without the paid V3 contract may not create. */
export function freeCoffeeCreateClosed(enabled: boolean, input: CommerceCreateInput): boolean {
  return enabled && input.readingType === 'coffee' && input.coffeeCaptureContract !== 'three_view_v3';
}

/**
 * Commerce on: `/v1/ai/complete` coffee_analysis may only fulfil a legacy
 * (non-V3) Coffee operation made before the rollout, owned by the caller and
 * already claimed (`processing`). Inline images, waiting, finished, missing
 * or foreign operations would be a new free reading.
 */
export async function claimedLegacyCoffee(
  operations: OperationLookup | undefined,
  ownerUserId: string,
  payload: unknown,
): Promise<boolean> {
  const operation = await claimedOperation(operations, ownerUserId, payload);
  return operation?.readingType === 'coffee' &&
    operation.coffeeCaptureContract == null;
}

/**
 * Commerce on: `/v1/ai/complete` palm_analysis may only fulfil a Palm
 * operation made before the rollout (it waited; a paid Palm is instant and
 * belongs to the worker), owned by the caller and already claimed. The first
 * request key (phase suffix aside) is pinned to the operation, so the same
 * claimed operation cannot buy another reading under a new key.
 */
export async function claimedLegacyPalm(input: {
  operations: OperationLookup | undefined;
  store: FirestoreLike | undefined;
  ownerUserId: string;
  payload: unknown;
  idempotencyKey: string | null;
}): Promise<boolean> {
  const operation = await claimedOperation(input.operations, input.ownerUserId, input.payload);
  if (operation?.readingType !== 'palm' || !(operation.readyAtMs > operation.createdAtMs)) return false;
  const requestKey = ritualOperationId(input.idempotencyKey);
  const store = input.store;
  if (!store || !requestKey) return false;
  try {
    return await store.runTransaction(async (tx) => {
      const ref = store.collection(LEGACY_DIRECT_AI).doc(operation.operationId);
      const pinned = (await tx.get(ref)).data();
      if (pinned) return pinned.ownerUserId === input.ownerUserId && pinned.requestKey === requestKey;
      tx.set(ref, { ownerUserId: input.ownerUserId, requestKey, readingType: 'palm' });
      return true;
    });
  } catch {
    return false;
  }
}

type OperationLookup = { getById(operationId: string): Promise<ReadingOperationRecord | null> };

/** The caller's own operation named by the payload, when it is claimed (`processing`). */
async function claimedOperation(
  operations: OperationLookup | undefined,
  ownerUserId: string,
  payload: unknown,
): Promise<ReadingOperationRecord | null> {
  const operationId = payload && typeof payload === 'object'
    ? (payload as Record<string, unknown>).operationId
    : null;
  if (!operations || typeof operationId !== 'string') return null;
  let operation: ReadingOperationRecord | null;
  try {
    operation = await operations.getById(operationId);
  } catch {
    return null;
  }
  return operation?.ownerUserId === ownerUserId && operation.status === 'processing' ? operation : null;
}

export function readingFulfillmentOpen(config: AppConfig): boolean {
  return config.aiSpendKillSwitch !== true
    && config.aiDailySpendCapMicros != null
    && config.aiDailySpendCapMicros > 0
    && config.openaiApiKey != null
    && config.openaiVision === true;
}

export async function readingBudgetOpen(
  store: FirestoreLike,
  config: AppConfig,
  nowMs: number,
): Promise<boolean> {
  if (!readingFulfillmentOpen(config)) return false;
  const day = new Date(nowMs).toISOString().slice(0, 10);
  const snap = await store.collection(SPEND_DAYS).doc(day).get();
  const total = snap.data()?.totalMicros;
  const spent = typeof total === 'number' && total > 0 ? total : 0;
  return spent < (config.aiDailySpendCapMicros ?? 0);
}

export async function openCommerceCreate(input: {
  config: AppConfig;
  store: FirestoreLike | null;
  service: ReadingOperationService;
  ownerUserId: string;
  nowMs: number;
  body: CommerceCreateInput;
}): Promise<
  | { kind: 'skip' }
  | { kind: 'record'; record: ReadingOperationRecord }
  | { kind: 'error'; httpStatus: number; code: ErrorCodeName }
> {
  if (freeCoffeeCreateClosed(input.config.readingCommerceEnabled, input.body)) {
    // Only the same create made before the rollout comes back; never a new one.
    const existing = await input.service.findCreated({ ownerUserId: input.ownerUserId, ...input.body });
    return existing
      ? { kind: 'record', record: existing }
      : { kind: 'error', httpStatus: 403, code: ErrorCode.readingEntitlementRequired };
  }
  if (!commerceApplies(input.config.readingCommerceEnabled, input.body)) return { kind: 'skip' };
  // A retry of a create made before the rollout (it waited) is that operation,
  // not a new reading: no credit, no budget.
  const earlier = await input.service.findCreated({ ownerUserId: input.ownerUserId, ...input.body });
  if (earlier && earlier.readyAtMs > earlier.createdAtMs) return { kind: 'record', record: earlier };
  if (!input.store) return { kind: 'error', httpStatus: 503, code: ErrorCode.noConfiguration };
  if (!(await readingBudgetOpen(input.store, input.config, input.nowMs))) {
    return { kind: 'error', httpStatus: 503, code: ErrorCode.spendGuard };
  }
  const feature: ReadingCommerceFeature = input.body.readingType === 'palm' ? 'palm' : 'coffee';
  const ledger = new ReadingEntitlementLedger(input.store);
  await ledger.reconcile({
    ownerUserId: input.ownerUserId,
    nowMs: input.nowMs,
    lookup: async (operationId) => {
      try {
        return await input.service.get(input.ownerUserId, operationId);
      } catch {
        return null;
      }
    },
  });
  const operationId = randomBytes(16).toString('hex');
  const consumed = await ledger.consume({
    ownerUserId: input.ownerUserId,
    feature,
    sourceRequestId: input.body.sourceRequestId,
    operationId,
    atMs: input.nowMs,
  });
  if (!consumed.ok) {
    const closed = consumed.reason === 'closed';
    return {
      kind: 'error',
      httpStatus: closed ? 409 : 403,
      code: closed ? ErrorCode.invalidRequest : ErrorCode.readingEntitlementRequired,
    };
  }
  try {
    const record = await input.service.create({
      ownerUserId: input.ownerUserId,
      readingType: input.body.readingType,
      sourceRequestId: input.body.sourceRequestId,
      language: input.body.language,
      executionMode: input.body.executionMode,
      coffeeIntention: input.body.coffeeIntention,
      coffeeInputContract: input.body.coffeeInputContract,
      coffeeCaptureContract: input.body.coffeeCaptureContract,
      instant: true,
      operationId,
    });
    if (record.operationId !== operationId) {
      if (record.readyAtMs === record.createdAtMs) {
        await ledger.bind(consumed.holdId, record.operationId);
        return { kind: 'record', record };
      }
      await ledger.restoreBySource(input.ownerUserId, input.body.sourceRequestId);
      return { kind: 'record', record };
    }
    await ledger.bind(consumed.holdId, record.operationId);
    return { kind: 'record', record };
  } catch (error) {
    await ledger.restoreBySource(input.ownerUserId, input.body.sourceRequestId);
    if (error instanceof ReadingOperationError) throw error;
    return { kind: 'error', httpStatus: 503, code: ErrorCode.noConfiguration };
  }
}
