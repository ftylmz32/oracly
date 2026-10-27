/**
 * Daily free-text allowance. One identity, one server day, thirty new
 * operations. Attempt 2 of the same tarot or yıldızname reading shares
 * that operation. Deep tarot, coffee, palm, dream, and soulmate stay outside.
 */
import { createHash } from 'node:crypto';
import { assertNoDeletionBarrier, deletionBarrierExists } from '../account/deletion-barrier.js';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, errorEnvelope } from '../errors.js';
import type { ServerClock } from './clock.js';
import { toEpochMs } from './clock.js';
import { serverDayKey } from './gem-wallet-policy.js';

export const FREE_TEXT_DAILY_LIMIT = 30;
const CLAIM_MS = 70_000;
const OPERATION_ID = /^[A-Za-z0-9._:-]{8,128}$/;
const ATTEMPT_SUFFIX = /:(?:nv2|yv1):a[12]$/;
const COUNTERS = 'freeTextQuota';
const ATTEMPTS = 'freeTextQuotaAttempts';

const GATED = new Set(['chat', 'oracle', 'yildizname_reading']);

type Charge = { state: 'open' | 'done'; live: number };

export type FreeTextHold = { operationId: string; fullKey: string; day: string };

export type FreeTextAdmission =
  | { action: 'skip' }
  | { action: 'reply'; status: number; payload: unknown }
  | { action: 'hold'; hold: FreeTextHold };

export function freeTextQuotaApplies(operation: string, paidTarot: boolean): boolean {
  if (paidTarot) return false;
  if (operation === 'tarot_reading') return true;
  return GATED.has(operation);
}

/** Narrative and yıldızname attempt 2 share the reading's operation id. */
export function freeTextOperationId(idempotencyKey: string | null): string | null {
  if (!idempotencyKey) return null;
  const operationId = idempotencyKey.replace(ATTEMPT_SUFFIX, '');
  return OPERATION_ID.test(operationId) ? operationId : null;
}

function locked(config: AppConfig): boolean {
  return config.appEnv === 'production' || config.appEnv === 'staging';
}

function docId(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}

function chargesOf(data: Record<string, unknown> | undefined): Record<string, Charge> {
  const raw = data?.charges;
  if (!raw || typeof raw !== 'object') return {};
  const charges: Record<string, Charge> = {};
  for (const [id, value] of Object.entries(raw as Record<string, unknown>)) {
    if (!value || typeof value !== 'object') continue;
    const row = value as { state?: unknown; live?: unknown };
    if (row.state !== 'open' && row.state !== 'done') continue;
    charges[id] = { state: row.state, live: typeof row.live === 'number' ? row.live : 0 };
  }
  return charges;
}

function countOf(data: Record<string, unknown> | undefined): number {
  return typeof data?.count === 'number' ? data.count : 0;
}

export async function admitFreeTextQuota(input: {
  config: AppConfig;
  store: FirestoreLike | undefined;
  clock: ServerClock;
  operation: string;
  paidTarot: boolean;
  identity: string;
  idempotencyKey: string | null;
}): Promise<FreeTextAdmission> {
  if (!freeTextQuotaApplies(input.operation, input.paidTarot)) return { action: 'skip' };
  if (!input.store) {
    if (!locked(input.config)) return { action: 'skip' };
    return { action: 'reply', status: 503, payload: errorEnvelope(ErrorCode.noConfiguration) };
  }
  const fullKey = input.idempotencyKey;
  const operationId = freeTextOperationId(fullKey);
  if (!fullKey || !operationId) {
    return { action: 'reply', status: 200, payload: errorEnvelope(ErrorCode.invalidRequest) };
  }
  const day = serverDayKey(input.clock.now());
  const now = toEpochMs(input.clock.now());
  const store = input.store;
  const counterRef = store.collection(COUNTERS).doc(docId(`${input.identity}\0${day}`));
  const attemptRef = store.collection(ATTEMPTS).doc(docId(`${input.identity}\0${fullKey}`));
  return store.runTransaction(async (tx) => {
    // A deleted (or being deleted) account gets no new or replayed record.
    await assertNoDeletionBarrier(tx, store, input.identity);
    const [counterSnap, attemptSnap] = await Promise.all([tx.get(counterRef), tx.get(attemptRef)]);
    const attempt = attemptSnap.data();
    const body = typeof attempt?.body === 'string' ? attempt.body : undefined;
    if (body && attempt?.identity === input.identity) {
      try {
        return { action: 'reply' as const, status: 200, payload: JSON.parse(body) as unknown };
      } catch {
        return { action: 'reply' as const, status: 409, payload: errorEnvelope(ErrorCode.rateLimited) };
      }
    }
    const claimUntil = typeof attempt?.claimUntilMs === 'number' ? attempt.claimUntilMs : 0;
    if (attempt?.identity === input.identity && attempt?.status === 'open' && claimUntil > now) {
      return { action: 'reply' as const, status: 409, payload: errorEnvelope(ErrorCode.rateLimited) };
    }
    const charges = chargesOf(counterSnap.data());
    const existing = charges[operationId];
    if (!existing && countOf(counterSnap.data()) >= FREE_TEXT_DAILY_LIMIT) {
      return { action: 'reply' as const, status: 200, payload: errorEnvelope(ErrorCode.dailyQuota) };
    }
    const count = existing ? countOf(counterSnap.data()) : countOf(counterSnap.data()) + 1;
    charges[operationId] = {
      state: existing?.state === 'done' ? 'done' : 'open',
      live: (existing?.live ?? 0) + 1,
    };
    tx.set(counterRef, { identity: input.identity, day, count, charges });
    tx.set(attemptRef, {
      identity: input.identity,
      operationId,
      fullKey,
      day,
      status: 'open',
      claimUntilMs: now + CLAIM_MS,
    });
    return { action: 'hold' as const, hold: { operationId, fullKey, day } };
  });
}

export async function finishFreeTextQuota(
  store: FirestoreLike,
  identity: string,
  hold: FreeTextHold,
  body: unknown,
): Promise<void> {
  const raw = typeof body === 'string' ? body : JSON.stringify(body);
  const counterRef = store.collection(COUNTERS).doc(docId(`${identity}\0${hold.day}`));
  const attemptRef = store.collection(ATTEMPTS).doc(docId(`${identity}\0${hold.fullKey}`));
  await store.runTransaction(async (tx) => {
    // Deleted owner: keep no text and no counter (the sweep removes the rest).
    if (await deletionBarrierExists(tx, store, identity)) return;
    const [counterSnap, attemptSnap] = await Promise.all([tx.get(counterRef), tx.get(attemptRef)]);
    const attempt = attemptSnap.data();
    if (!attempt || attempt.identity !== identity) return;
    const charges = chargesOf(counterSnap.data());
    const row = charges[hold.operationId] ?? { state: 'open' as const, live: 1 };
    charges[hold.operationId] = { state: 'done', live: Math.max(0, row.live - 1) };
    tx.set(counterRef, {
      identity,
      day: hold.day,
      count: countOf(counterSnap.data()),
      charges,
    });
    tx.set(attemptRef, { ...attempt, status: 'final', body: raw, claimUntilMs: 0 });
  });
}

export async function failFreeTextQuota(
  store: FirestoreLike,
  identity: string,
  hold: FreeTextHold,
): Promise<void> {
  const counterRef = store.collection(COUNTERS).doc(docId(`${identity}\0${hold.day}`));
  const attemptRef = store.collection(ATTEMPTS).doc(docId(`${identity}\0${hold.fullKey}`));
  await store.runTransaction(async (tx) => {
    // Deleted owner: keep no text and no counter (the sweep removes the rest).
    if (await deletionBarrierExists(tx, store, identity)) return;
    const [counterSnap, attemptSnap] = await Promise.all([tx.get(counterRef), tx.get(attemptRef)]);
    const attempt = attemptSnap.data();
    if (!attempt || attempt.identity !== identity || attempt.status === 'final') return;
    const charges = chargesOf(counterSnap.data());
    const row = charges[hold.operationId];
    let count = countOf(counterSnap.data());
    if (row && row.state !== 'done') {
      const live = Math.max(0, row.live - 1);
      if (live === 0) {
        delete charges[hold.operationId];
        count = Math.max(0, count - 1);
      } else {
        charges[hold.operationId] = { state: 'open', live };
      }
    } else if (row) {
      charges[hold.operationId] = { state: 'done', live: Math.max(0, row.live - 1) };
    }
    tx.set(counterRef, { identity, day: hold.day, count, charges });
    tx.set(attemptRef, { ...attempt, status: 'refunded', claimUntilMs: 0 });
  });
}
