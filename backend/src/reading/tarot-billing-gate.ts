/**
 * One deep-tarot charge, shared with the existing settle key.
 * A usable result is reserved before it is returned. Settle replays that debit.
 */
import { createHash, randomBytes } from 'node:crypto';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import { ErrorCode, errorEnvelope } from '../errors.js';
import type { AppConfig } from '../config.js';
import type { ValidatedRequest } from '../ai/validate-request.js';
import { toEpochMs, type ServerClock } from './clock.js';
import { GemLedger, GemLedgerError } from './gem-ledger.js';
import { GEM_TAROT_READING_COST } from './gem-wallet-policy.js';
import { isPaidTarot, parseTarotBillingId, tarotSettleKey } from './tarot-billing-id.js';

const HOLDS = 'tarotHolds';
const INDEX = 'tarotHoldIndex';
const CLAIM_MS = 70_000;
const STALE_MS = 15 * 60_000;

export type TarotHold = {
  ownerUserId: string;
  operationId: string;
  fingerprint: string;
  attempt: 1 | 2 | null;
  claimId: string;
};

export type TarotAdmission =
  | { action: 'skip' }
  | { action: 'reply'; status: number; payload: unknown }
  | { action: 'hold'; hold: TarotHold };

type HoldDoc = {
  ownerUserId: string;
  operationId: string;
  fingerprint: string;
  status: 'open' | 'final' | 'refunding' | 'refunded';
  spendTransactionId: string;
  body: string | null;
  claimId: string | null;
  claimUntilMs: number;
  updatedAtMs: number;
};

export function tarotBillingActive(
  config: AppConfig,
  ledger: GemLedger | undefined,
  store: FirestoreLike | undefined,
): boolean {
  if (ledger && store) return true;
  return config.appEnv === 'production' || config.appEnv === 'staging';
}

export async function admitPaidTarot(input: {
  config: AppConfig;
  ledger?: GemLedger;
  store?: FirestoreLike;
  clock: ServerClock;
  validated: ValidatedRequest;
  identity: string;
  idemKey: string | null;
  fingerprint: string;
}): Promise<TarotAdmission> {
  if (!isPaidTarot(input.validated)) return { action: 'skip' };
  if (!input.ledger || !input.store) {
    if (tarotBillingActive(input.config, input.ledger, input.store)) {
      return reply(503, ErrorCode.noConfiguration);
    }
    return { action: 'skip' };
  }
  const parsed = parseTarotBillingId(input.idemKey);
  if (!parsed) return reply(400, ErrorCode.invalidRequest);
  const now = toEpochMs(input.clock.now());
  await releaseAbandonedTarotHolds(
    input.ledger,
    input.store,
    input.clock,
    input.identity,
    parsed.operationId,
  );
  let spendTransactionId = '';
  try {
    const debit = await input.ledger.debit({
      ownerUserId: input.identity,
      amount: GEM_TAROT_READING_COST,
      idempotencyKey: tarotSettleKey(parsed.operationId),
      operationId: parsed.operationId,
      reason: 'tarot_reading',
    });
    spendTransactionId = debit.transactionId;
  } catch (error) {
    if (error instanceof GemLedgerError && error.code === 'insufficient_gems') {
      return reply(409, ErrorCode.insufficientGems);
    }
    return reply(503, ErrorCode.noConfiguration);
  }
  const claimId = randomBytes(8).toString('hex');
  return decideHold(input.store, {
    ownerUserId: input.identity,
    operationId: parsed.operationId,
    fingerprint: input.fingerprint,
    attempt: parsed.attempt,
    claimId,
    now,
    spendTransactionId,
  });
}

export async function finishPaidTarot(
  store: FirestoreLike,
  clock: ServerClock,
  ledger: GemLedger | null,
  hold: TarotHold,
  envelope: unknown,
): Promise<{ deliver: true } | { deliver: false; status: number; payload: unknown }> {
  if (!usable(envelope)) {
    await failPaidTarot(store, clock, hold, ledger);
    return { deliver: false, status: 200, payload: errorEnvelope(ErrorCode.invalidResponse) };
  }
  const body = JSON.stringify(envelope);
  const stored = body.length <= 200_000 ? body : null;
  const now = toEpochMs(clock.now());
  const deliver = await store.runTransaction(async (tx) => {
    const ref = store.collection(HOLDS).doc(docId(hold.ownerUserId, hold.operationId));
    const current = parseHold((await tx.get(ref)).data());
    if (!current || current.status === 'refunded' || current.status === 'refunding') return false;
    if (current.status === 'final') return true;
    if (current.claimId && current.claimId !== hold.claimId && current.claimUntilMs > now) {
      return false;
    }
    const final = hold.attempt !== 1;
    tx.set(ref, {
      ...current,
      body: stored ?? current.body,
      status: final ? 'final' : 'open',
      claimId: null,
      claimUntilMs: 0,
      updatedAtMs: now,
    });
    return true;
  });
  if (!deliver) return { deliver: false, status: 409, payload: errorEnvelope(ErrorCode.invalidRequest) };
  return { deliver: true };
}

export async function failPaidTarot(
  store: FirestoreLike,
  clock: ServerClock,
  hold: TarotHold,
  ledger: GemLedger | null,
): Promise<void> {
  const now = toEpochMs(clock.now());
  const spend = await store.runTransaction(async (tx) => {
    const ref = store.collection(HOLDS).doc(docId(hold.ownerUserId, hold.operationId));
    const current = parseHold((await tx.get(ref)).data());
    if (!current || current.status === 'final' || current.status === 'refunded') return null;
    if (current.claimId && current.claimId !== hold.claimId && current.claimUntilMs > now) return null;
    if (current.body || hold.attempt === 1) {
      tx.set(ref, {
        ...current,
        status: current.body ? 'final' : 'open',
        claimId: null,
        claimUntilMs: 0,
        updatedAtMs: now,
      });
      return null;
    }
    tx.set(ref, { ...current, status: 'refunding', claimUntilMs: 0, updatedAtMs: now });
    return current.spendTransactionId;
  });
  if (!spend || !ledger) return;
  await ledger.credit({
    ownerUserId: hold.ownerUserId,
    amount: GEM_TAROT_READING_COST,
    idempotencyKey: `refund:${spend}`,
    reason: 'tarot_reading_refund',
  });
  await store.runTransaction(async (tx) => {
    const ref = store.collection(HOLDS).doc(docId(hold.ownerUserId, hold.operationId));
    const current = parseHold((await tx.get(ref)).data());
    if (!current || current.status === 'final') return;
    tx.set(ref, { ...current, status: 'refunded', claimId: null, claimUntilMs: 0, updatedAtMs: now });
  });
}

export async function markTarotHoldFinal(
  store: FirestoreLike,
  ownerUserId: string,
  operationId: string,
  nowMs: number,
): Promise<void> {
  await store.runTransaction(async (tx) => {
    const ref = store.collection(HOLDS).doc(docId(ownerUserId, operationId));
    const current = parseHold((await tx.get(ref)).data());
    if (!current || current.status !== 'open') return;
    tx.set(ref, { ...current, status: 'final', claimId: null, claimUntilMs: 0, updatedAtMs: nowMs });
  });
}

export async function releaseAbandonedTarotHolds(
  ledger: GemLedger,
  store: FirestoreLike,
  clock: ServerClock,
  ownerUserId: string,
  exceptOperationId?: string,
): Promise<void> {
  const now = toEpochMs(clock.now());
  const indexRef = store.collection(INDEX).doc(docId(ownerUserId, 'index'));
  const indexSnap = await indexRef.get();
  const ids = Array.isArray(indexSnap.data()?.ids)
    ? (indexSnap.data()?.ids as unknown[]).filter((id): id is string => typeof id === 'string')
    : [];
  for (const operationId of ids) {
    if (operationId === exceptOperationId) continue;
    const ref = store.collection(HOLDS).doc(docId(ownerUserId, operationId));
    const current = parseHold((await ref.get()).data());
    if (!current || current.status !== 'open' || current.body) continue;
    if (current.claimUntilMs > now || now - current.updatedAtMs < STALE_MS) continue;
    await failPaidTarot(
      store,
      clock,
      {
        ownerUserId,
        operationId,
        fingerprint: current.fingerprint,
        attempt: null,
        claimId: current.claimId ?? 'sweep',
      },
      ledger,
    );
  }
}

async function decideHold(
  store: FirestoreLike,
  input: TarotHold & { now: number; spendTransactionId: string },
): Promise<TarotAdmission> {
  return store.runTransaction(async (tx) => {
    const ref = store.collection(HOLDS).doc(docId(input.ownerUserId, input.operationId));
    const indexRef = store.collection(INDEX).doc(docId(input.ownerUserId, 'index'));
    const current = parseHold((await tx.get(ref)).data());
    const indexSnap = await tx.get(indexRef);
    const ids = Array.isArray(indexSnap.data()?.ids)
      ? (indexSnap.data()?.ids as unknown[]).filter((id): id is string => typeof id === 'string')
      : [];
    if (!ids.includes(input.operationId)) {
      tx.set(indexRef, { ids: [...ids, input.operationId].slice(-8) });
    }
    if (!current) {
      tx.set(ref, openDoc(input));
      return { action: 'hold', hold: input };
    }
    if (current.fingerprint !== input.fingerprint) return reply(409, ErrorCode.invalidRequest);
    if (current.status === 'refunded' || current.status === 'refunding') {
      return reply(409, ErrorCode.invalidRequest);
    }
    if (current.body && (current.status === 'final' || input.attempt !== 2)) {
      try {
        return { action: 'reply', status: 200, payload: JSON.parse(current.body) as unknown };
      } catch {
        return reply(409, ErrorCode.invalidRequest);
      }
    }
    if (current.claimUntilMs > input.now) return reply(409, ErrorCode.rateLimited);
    tx.set(ref, {
      ...current,
      claimId: input.claimId,
      claimUntilMs: input.now + CLAIM_MS,
      updatedAtMs: input.now,
    });
    return { action: 'hold', hold: input };
  });
}

function openDoc(input: TarotHold & { now: number; spendTransactionId: string }): HoldDoc {
  return {
    ownerUserId: input.ownerUserId,
    operationId: input.operationId,
    fingerprint: input.fingerprint,
    status: 'open',
    spendTransactionId: input.spendTransactionId,
    body: null,
    claimId: input.claimId,
    claimUntilMs: input.now + CLAIM_MS,
    updatedAtMs: input.now,
  };
}

function parseHold(data: Record<string, unknown> | undefined): HoldDoc | null {
  if (!data || typeof data.operationId !== 'string' || typeof data.ownerUserId !== 'string') {
    return null;
  }
  const status = data.status;
  if (status !== 'open' && status !== 'final' && status !== 'refunding' && status !== 'refunded') {
    return null;
  }
  return {
    ownerUserId: data.ownerUserId,
    operationId: data.operationId,
    fingerprint: typeof data.fingerprint === 'string' ? data.fingerprint : '',
    status,
    spendTransactionId: typeof data.spendTransactionId === 'string' ? data.spendTransactionId : '',
    body: typeof data.body === 'string' ? data.body : null,
    claimId: typeof data.claimId === 'string' ? data.claimId : null,
    claimUntilMs: typeof data.claimUntilMs === 'number' ? data.claimUntilMs : 0,
    updatedAtMs: typeof data.updatedAtMs === 'number' ? data.updatedAtMs : 0,
  };
}

function usable(envelope: unknown): boolean {
  if (!envelope || typeof envelope !== 'object') return false;
  const data = (envelope as { data?: unknown }).data;
  if (!data || typeof data !== 'object') return false;
  const record = data as Record<string, unknown>;
  if (typeof record.text === 'string') return record.text.trim().length > 0;
  return Object.keys(record).length > 0;
}

function reply(status: number, code: (typeof ErrorCode)[keyof typeof ErrorCode]): TarotAdmission {
  return { action: 'reply', status, payload: errorEnvelope(code) };
}

function docId(ownerUserId: string, operationId: string): string {
  return createHash('sha256').update(`${ownerUserId}\0${operationId}`).digest('hex');
}
