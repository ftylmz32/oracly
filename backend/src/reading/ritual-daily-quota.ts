/**
 * Separate daily allowances for free coffee, palm, and dream readings.
 * One identity, one UTC day, one operation id. Premium and gems are not
 * involved. A stored body replays. A client abort keeps the slot.
 */
import { createHash } from 'node:crypto';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, errorEnvelope } from '../errors.js';
import type { ServerClock } from './clock.js';
import { toEpochMs } from './clock.js';
import { serverDayKey } from './gem-wallet-policy.js';

/** Astrology: one personal reading a day; a second covers a mid-day birth-data change. */
export const RITUAL_DAILY_LIMIT = { coffee: 1, palm: 2, dream: 3, astrology: 2 } as const;
export type RitualKind = keyof typeof RITUAL_DAILY_LIMIT;

const CLAIM_MS = 70_000;
const OPERATION_ID = /^[A-Za-z0-9._:-]{8,128}$/;
const PHASE_SUFFIX = /:(?:observe|write)$/;
export const RITUAL_COUNTERS = 'ritualDailyQuota';
export const RITUAL_ATTEMPTS = 'ritualDailyQuotaAttempts';

const CODE = {
  coffee: ErrorCode.coffeeDailyQuota,
  palm: ErrorCode.palmDailyQuota,
  dream: ErrorCode.dreamDailyQuota,
  astrology: ErrorCode.astrologyDailyQuota,
} as const;

type Charge = { state: 'open' | 'done'; live: number };
export type RitualHold = { kind: RitualKind; operationId: string; fullKey: string; day: string };
export type RitualAdmission =
  | { action: 'skip' }
  | { action: 'reply'; status: number; payload: unknown }
  | { action: 'stored'; body: unknown; hold: RitualHold }
  | { action: 'hold'; hold: RitualHold };

export function ritualKindOf(operation: string): RitualKind | null {
  if (operation === 'coffee_analysis') return 'coffee';
  if (operation === 'palm_analysis') return 'palm';
  if (operation === 'dream_analysis') return 'dream';
  if (operation === 'astrology_daily') return 'astrology';
  return null;
}

export function ritualOperationId(idempotencyKey: string | null): string | null {
  if (!idempotencyKey) return null;
  const operationId = idempotencyKey.replace(PHASE_SUFFIX, '');
  return OPERATION_ID.test(operationId) ? operationId : null;
}

function locked(config: AppConfig): boolean {
  return config.appEnv === 'production' || config.appEnv === 'staging';
}

export function docId(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}

export function countOf(data: Record<string, unknown> | undefined): number {
  return typeof data?.count === 'number' ? data.count : 0;
}

export function chargesOf(data: Record<string, unknown> | undefined): Record<string, Charge> {
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

export async function admitRitualQuota(input: {
  config: AppConfig;
  store: FirestoreLike | undefined;
  clock: ServerClock;
  operation: string;
  identity: string;
  idempotencyKey: string | null;
}): Promise<RitualAdmission> {
  const kind = ritualKindOf(input.operation);
  if (!kind) return { action: 'skip' };
  if (!input.store) {
    if (!locked(input.config)) return { action: 'skip' };
    return { action: 'reply', status: 503, payload: errorEnvelope(ErrorCode.noConfiguration) };
  }
  const fullKey = input.idempotencyKey;
  const operationId = ritualOperationId(fullKey);
  if (!fullKey || !operationId) {
    return { action: 'reply', status: 200, payload: errorEnvelope(ErrorCode.invalidRequest) };
  }
  const day = serverDayKey(input.clock.now());
  const now = toEpochMs(input.clock.now());
  const store = input.store;
  const counterRef = store.collection(RITUAL_COUNTERS).doc(docId(`${input.identity}\0${day}\0${kind}`));
  const attemptRef = store.collection(RITUAL_ATTEMPTS).doc(docId(`${input.identity}\0${kind}\0${fullKey}`));
  const limit = RITUAL_DAILY_LIMIT[kind];
  return store.runTransaction(async (tx) => {
    const [counterSnap, attemptSnap] = await Promise.all([tx.get(counterRef), tx.get(attemptRef)]);
    const attempt = attemptSnap.data();
    const hold: RitualHold = { kind, operationId, fullKey, day };
    const body = typeof attempt?.body === 'string' ? attempt.body : undefined;
    if (body && attempt?.identity === input.identity) {
      try {
        return { action: 'stored' as const, body: JSON.parse(body) as unknown, hold };
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
    if (!existing && countOf(counterSnap.data()) >= limit) {
      return { action: 'reply' as const, status: 200, payload: errorEnvelope(CODE[kind]) };
    }
    const count = existing ? countOf(counterSnap.data()) : countOf(counterSnap.data()) + 1;
    charges[operationId] = {
      state: existing?.state === 'done' ? 'done' : 'open',
      live: (existing?.live ?? 0) + 1,
    };
    tx.set(counterRef, { identity: input.identity, day, kind, count, charges });
    tx.set(attemptRef, {
      identity: input.identity, operationId, fullKey, day, kind, status: 'open', claimUntilMs: now + CLAIM_MS,
    });
    return { action: 'hold' as const, hold };
  });
}
