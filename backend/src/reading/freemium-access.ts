/**
 * Freemium V1 (dark): who may open a new Coffee V3 or Palm reading today.
 * Order: the day's own allowance (free 1; Premium 2 in total) → an existing
 * reading credit. No new sale is opened here.
 *
 * The allowance is reserved on the same ritual daily counter the worker
 * charges, inside one transaction, under the new operation id. The worker
 * then finds that charge and never counts the reading twice; its existing
 * refund paths return the slot. A slot whose reading has since failed is
 * free again. Premium comes only from the server entitlement snapshot.
 *
 * Access only: no AI call, prompt, model, image or output is touched here.
 */
import { createHash } from 'node:crypto';
import { assertNoDeletionBarrier } from '../account/deletion-barrier.js';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import type { AppConfig } from '../config.js';
import { ErrorCode } from '../errors.js';
import { serverDayKey } from './gem-wallet-policy.js';
import type { ReadingOperationRecord } from './operation-model.js';
import type { ReadingOperationService } from './operation-service.js';
import {
  commerceApplies,
  openCreditCreate,
  readingBudgetOpen,
  type CommerceCreateInput,
  type CommerceCreateOutcome,
} from './reading-commerce-gate.js';
import { chargesOf, countOf, docId, RITUAL_COUNTERS } from './ritual-daily-quota.js';
import type { SoulmateEntitlementGuard } from './soulmate-entitlement-guard.js';

export type FreemiumKind = 'coffee' | 'palm';
export type FreemiumTier = 'free' | 'premium' | 'credit';

/** Daily totals, not additions: Premium is 2 a day in all. */
export const FREEMIUM_DAILY_LIMIT = {
  free: { coffee: 1, palm: 1 },
  premium: { coffee: 2, palm: 2 },
} as const;

/** Free readings may use at most this share of the day's AI ceiling. */
export const FREEMIUM_FREE_SPEND_PERCENT = 30;

/** Server-only: how each Freemium operation was opened (tier, slot day). */
export const FREEMIUM_ACCESS = 'freemiumAccess';
/** Server-only: the day's AI spend by access tier. */
export const FREEMIUM_SPEND_DAYS = 'freemiumSpendDays';

export type FreemiumAccessRecord = {
  ownerUserId: string;
  kind: FreemiumKind;
  tier: FreemiumTier;
  day: string;
};

/** The same creates reading commerce covers: Palm and three-view Coffee V3. */
export function freemiumApplies(config: AppConfig, body: CommerceCreateInput): boolean {
  return config.freemiumV1Enabled && commerceApplies(true, body);
}

/** Zero when the day ceiling is missing: free use is never unbounded. */
export function freeSpendCapMicros(config: AppConfig): number {
  const cap = config.aiDailySpendCapMicros;
  if (cap == null || !Number.isFinite(cap) || cap <= 0) return 0;
  return Math.floor((cap * FREEMIUM_FREE_SPEND_PERCENT) / 100);
}

export async function freeBudgetOpen(
  store: FirestoreLike,
  config: AppConfig,
  nowMs: number,
): Promise<boolean> {
  const cap = freeSpendCapMicros(config);
  if (cap <= 0 || !(await readingBudgetOpen(store, config, nowMs))) return false;
  const snap = await store.collection(FREEMIUM_SPEND_DAYS).doc(serverDayKey(new Date(nowMs))).get();
  const spent = snap.data()?.freeMicros;
  return (typeof spent === 'number' && spent > 0 ? spent : 0) < cap;
}

export async function freemiumAccessFor(
  store: FirestoreLike,
  operationId: string,
): Promise<FreemiumAccessRecord | null> {
  const data = (await store.collection(FREEMIUM_ACCESS).doc(operationId).get()).data();
  if (!data || typeof data.ownerUserId !== 'string' || typeof data.day !== 'string') return null;
  if (data.kind !== 'coffee' && data.kind !== 'palm') return null;
  if (data.tier !== 'free' && data.tier !== 'premium' && data.tier !== 'credit') return null;
  return { ownerUserId: data.ownerUserId, kind: data.kind, tier: data.tier, day: data.day };
}

/**
 * The worker's quota slot for an operation opened under Freemium: the day
 * and tier limit it was reserved under. Null keeps the default admission.
 */
export async function freemiumSlotFor(
  config: AppConfig,
  store: FirestoreLike | undefined,
  ownerUserId: string,
  operationId: string,
): Promise<{ day: string; limit: number } | null> {
  if (!config.freemiumV1Enabled || !store) return null;
  const access = await freemiumAccessFor(store, operationId);
  if (!access || access.ownerUserId !== ownerUserId || access.tier === 'credit') return null;
  return { day: access.day, limit: FREEMIUM_DAILY_LIMIT[access.tier][access.kind] };
}

export async function openFreemiumCreate(input: {
  config: AppConfig;
  store: FirestoreLike | null;
  service: ReadingOperationService;
  premium: SoulmateEntitlementGuard | undefined;
  ownerUserId: string;
  nowMs: number;
  body: CommerceCreateInput;
}): Promise<Exclude<CommerceCreateOutcome, { kind: 'skip' }>> {
  const store = input.store;
  if (!store) return { kind: 'error', httpStatus: 503, code: ErrorCode.noConfiguration };
  // A retry of an earlier create is that operation: no second slot or credit.
  const earlier = await input.service.findCreated({ ownerUserId: input.ownerUserId, ...input.body });
  if (earlier) return { kind: 'record', record: earlier };
  const kind: FreemiumKind = input.body.readingType === 'palm' ? 'palm' : 'coffee';
  const premium = input.premium ? await input.premium.isPremiumActive(input.ownerUserId) : false;
  const tier: 'free' | 'premium' = premium ? 'premium' : 'free';
  const slotBudget = tier === 'free'
    ? await freeBudgetOpen(store, input.config, input.nowMs)
    : await readingBudgetOpen(store, input.config, input.nowMs);
  if (slotBudget) {
    const day = serverDayKey(new Date(input.nowMs));
    const operationId = freemiumOperationId(input.ownerUserId, input.body);
    const reserved = await reserveSlot(store, input.service, {
      ownerUserId: input.ownerUserId,
      kind,
      tier,
      day,
      operationId,
      limit: FREEMIUM_DAILY_LIMIT[tier][kind],
      nowMs: input.nowMs,
    });
    if (reserved) {
      let record: ReadingOperationRecord;
      try {
        record = await input.service.create({
          ownerUserId: input.ownerUserId,
          ...input.body,
          // Premium waits for nothing; a free reading keeps the wait policy.
          instant: tier === 'premium',
          operationId,
        });
      } catch (error) {
        await releaseSlot(store, input.ownerUserId, kind, day, operationId);
        throw error;
      }
      // An earlier create of the same request won: that one is the reading.
      if (record.operationId !== operationId) {
        await releaseSlot(store, input.ownerUserId, kind, day, operationId);
      }
      return { kind: 'record', record };
    }
  }
  const credit = await openCreditCreate({ ...input, store });
  if (credit.kind === 'record') {
    await noteAccess(store, credit.record.operationId, {
      ownerUserId: input.ownerUserId,
      kind,
      tier: 'credit',
      day: serverDayKey(new Date(input.nowMs)),
    });
    return credit;
  }
  if (credit.code !== ErrorCode.readingEntitlementRequired) return credit;
  // No credit either. Never a purchase prompt from the server: the day is used,
  // or today's free capacity is.
  if (!slotBudget) return { kind: 'error', httpStatus: 503, code: ErrorCode.spendGuard };
  return {
    kind: 'error',
    httpStatus: 429,
    code: kind === 'palm' ? ErrorCode.palmDailyQuota : ErrorCode.coffeeDailyQuota,
  };
}

/**
 * One id per owner + request: a raced repeat of the same create finds the
 * same reservation instead of a second slot (or a false "day used").
 */
function freemiumOperationId(ownerUserId: string, body: CommerceCreateInput): string {
  return createHash('sha256')
    .update(`freemium-v1\0${ownerUserId}\0${body.readingType}\0${body.sourceRequestId}`)
    .digest('hex')
    .slice(0, 32);
}

/** Reserve one slot on the day counter (idempotent per operation), or report the day full. */
async function reserveSlot(
  store: FirestoreLike,
  service: ReadingOperationService,
  input: {
    ownerUserId: string;
    kind: FreemiumKind;
    tier: 'free' | 'premium';
    day: string;
    operationId: string;
    limit: number;
    nowMs: number;
  },
): Promise<boolean> {
  const counterRef = store.collection(RITUAL_COUNTERS)
    .doc(docId(`${input.ownerUserId}\0${input.day}\0${input.kind}`));
  // A failed reading is terminal: its undelivered slot is free again.
  const failed = await failedOperations(
    service,
    input.ownerUserId,
    chargesOf((await counterRef.get()).data()),
  );
  return store.runTransaction(async (tx) => {
    await assertNoDeletionBarrier(tx, store, input.ownerUserId);
    const data = (await tx.get(counterRef)).data();
    const charges = chargesOf(data);
    let count = countOf(data);
    for (const id of failed) {
      if (charges[id] && charges[id].state !== 'done') {
        delete charges[id];
        count = Math.max(0, count - 1);
      }
    }
    if (charges[input.operationId]) {
      // The same request already holds this slot.
      if (failed.length > 0) tx.set(counterRef, counter(input, count, charges));
      return true;
    }
    if (count >= input.limit) {
      if (failed.length > 0) tx.set(counterRef, counter(input, count, charges));
      return false;
    }
    charges[input.operationId] = { state: 'open', live: 0 };
    tx.set(counterRef, counter(input, count + 1, charges));
    tx.set(store.collection(FREEMIUM_ACCESS).doc(input.operationId), {
      ownerUserId: input.ownerUserId,
      kind: input.kind,
      tier: input.tier,
      day: input.day,
      createdAtMs: input.nowMs,
    });
    return true;
  });
}

function counter(
  input: { ownerUserId: string; day: string; kind: FreemiumKind },
  count: number,
  charges: ReturnType<typeof chargesOf>,
) {
  return { identity: input.ownerUserId, day: input.day, kind: input.kind, count, charges };
}

async function failedOperations(
  service: ReadingOperationService,
  ownerUserId: string,
  charges: ReturnType<typeof chargesOf>,
): Promise<string[]> {
  const failed: string[] = [];
  for (const [id, row] of Object.entries(charges)) {
    if (row.state === 'done') continue;
    try {
      const operation = await service.get(ownerUserId, id);
      if (operation.status === 'failed') failed.push(id);
    } catch {
      // Not an operation (or not readable now): keep the charge.
    }
  }
  return failed;
}

/** Undo a reservation that never became the reading. */
async function releaseSlot(
  store: FirestoreLike,
  ownerUserId: string,
  kind: FreemiumKind,
  day: string,
  operationId: string,
): Promise<void> {
  const counterRef = store.collection(RITUAL_COUNTERS).doc(docId(`${ownerUserId}\0${day}\0${kind}`));
  await store.runTransaction(async (tx) => {
    const data = (await tx.get(counterRef)).data();
    const charges = chargesOf(data);
    const row = charges[operationId];
    if (!row || row.state === 'done' || row.live > 0) return;
    delete charges[operationId];
    tx.set(counterRef, {
      identity: ownerUserId,
      day,
      kind,
      count: Math.max(0, countOf(data) - 1),
      charges,
    });
    tx.delete(store.collection(FREEMIUM_ACCESS).doc(operationId));
  });
}

/** Records how a credit operation was opened; a slot record already there wins. */
async function noteAccess(
  store: FirestoreLike,
  operationId: string,
  record: FreemiumAccessRecord,
): Promise<void> {
  const ref = store.collection(FREEMIUM_ACCESS).doc(operationId);
  await store.runTransaction(async (tx) => {
    if ((await tx.get(ref)).exists) return;
    tx.set(ref, record);
  });
}
