import type { FirestoreLike } from '../billing/entitlement-repository.js';
import { Timestamp } from '@google-cloud/firestore';
import { systemClock, toEpochMs, type ServerClock } from './clock.js';

export type ReadingGenerationTrace = {
  pipelineVersion: string;
  interpretationContractVersion: string;
  promptRulesVersion: string;
  modelIdentifier: string;
};

export type ProviderStageState =
  | 'not_started'
  | 'in_flight'
  | 'provider_completed'
  | 'persisted'
  | 'provider_outcome_unknown'
  // SM-RL1 — a DEFINITIVE (not ambiguous) no-output provider rejection.
  // Written directly by the SAME execution that caught the rejection
  // (never left stranded as `in_flight` for a later claim to discover),
  // so callers who opt in via `markRejected` can bound a safe retry
  // without ever risking a duplicate paid call. Nothing writes these
  // states unless it explicitly calls `markRejected` — Coffee/Palm never
  // do, so their checkpoints can never enter either state and their
  // `claimAttempt` behavior is unchanged.
  | 'rejected_retryable'
  | 'rejected_terminal';
export type ProviderStageRecord = {
  state: ProviderStageState;
  output?: Record<string, unknown>;
  attemptId?: string;
  startedAtMs?: number;
  generationTrace?: ReadingGenerationTrace;
  /** SM-RL1 — present once any attempt has been claimed; used to bound retries. */
  attemptCount?: number;
  maxAttempts?: number;
  providerErrorCode?: string;
  /** SM-RL2 §5 — durably persisted (not just logged) so a future forensic
   * pass is never blocked the way SM-PR1 was: the checkpoint itself, not
   * only transient Cloud Logging, carries the provider's own 429
   * evidence. Same bounded/sanitized shape as ProviderRejectionInfo —
   * never a raw response body, never secrets. */
  requestId?: string;
  rateLimit?: Record<string, string>;
  providerMessage?: string;
  /** The provider's OWN Retry-After, distinct from the (possibly floor-
   * adjusted) `retryAfterMs` a caller passed into markRejected(). */
  rawRetryAfterMs?: number;
};
export type ProviderStageClaim = ProviderStageRecord & {
  initiate: boolean;
  /** SM-RL1 — true only when `state === 'rejected_retryable'` AND
   * `initiate === false` because the retry budget itself is spent (as
   * opposed to merely not-yet-time per `retryNotBeforeMs`). Callers use
   * this to distinguish "fail closed now, permanently" from "let Cloud
   * Tasks' own retry try again shortly." */
  budgetExhausted?: boolean;
};

/** SM-RL1 — persisted alongside a definitive rejection. Compact and safe:
 * no raw provider body, no personal data. A DURATION rather than an
 * absolute timestamp — the repository's own clock computes the actual
 * not-before instant, so a caller's clock can never drift from the one
 * `claimAttempt` later compares against. */
export type ProviderRejectionInfo = {
  retryable: boolean;
  providerErrorCode: string;
  /** Only meaningful when `retryable` is true. The chosen (possibly
   * floor-adjusted) delay — see soulmate-processor-execute.ts's
   * computeRateLimitBackoffMs. */
  retryAfterMs?: number;
  maxAttempts?: number;
  /** SM-RL2 §5 — bounded 429 evidence, persisted as-is onto the
   * checkpoint (never a raw response body, never secrets). */
  requestId?: string;
  rateLimit?: Record<string, string>;
  providerMessage?: string;
  rawRetryAfterMs?: number;
};

export interface ProviderStageRepository {
  get(operationId: string): Promise<ProviderStageRecord>;
  claimAttempt(operationId: string, ownerUserId: string, generationTrace?: ReadingGenerationTrace): Promise<ProviderStageClaim>;
  markInFlight(operationId: string, ownerUserId: string): Promise<void>;
  markCompleted(operationId: string, ownerUserId: string, output: Record<string, unknown>): Promise<void>;
  markPersisted(operationId: string): Promise<void>;
  markOutcomeUnknown(operationId: string): Promise<void>;
  /** SM-RL1 — records a DEFINITIVE (never ambiguous) provider rejection
   * for the CURRENT in-flight attempt. A no-op if the checkpoint is not
   * currently `in_flight` (already resolved by a concurrent path). */
  markRejected(operationId: string, ownerUserId: string, info: ProviderRejectionInfo): Promise<void>;
}

const MAX_PROVIDER_CHECKPOINT_BYTES = 256 * 1024;

/** Firestore checkpoints are control-plane records, never binary storage. */
export function assertCompactProviderCheckpoint(output: Record<string, unknown>): void {
  const seen = new Set<object>();
  const inspect = (value: unknown, key: string, depth: number): void => {
    if (depth > 12) throw new Error('provider_checkpoint_too_deep');
    if (Buffer.isBuffer(value) || value instanceof Uint8Array) {
      throw new Error('provider_checkpoint_binary_forbidden');
    }
    if (key.toLowerCase().includes('base64')) {
      throw new Error('provider_checkpoint_base64_forbidden');
    }
    if (!value || typeof value !== 'object') return;
    if (seen.has(value as object)) throw new Error('provider_checkpoint_cycle_forbidden');
    seen.add(value as object);
    if (Array.isArray(value)) {
      value.forEach((item) => inspect(item, '', depth + 1));
    } else {
      for (const [childKey, child] of Object.entries(value as Record<string, unknown>)) {
        inspect(child, childKey, depth + 1);
      }
    }
    seen.delete(value as object);
  };
  inspect(output, '', 0);
  let encoded: string;
  try {
    encoded = JSON.stringify(output);
  } catch {
    throw new Error('provider_checkpoint_not_serializable');
  }
  if (Buffer.byteLength(encoded, 'utf8') > MAX_PROVIDER_CHECKPOINT_BYTES) {
    throw new Error('provider_checkpoint_too_large');
  }
}

export class FirestoreProviderStageRepository implements ProviderStageRepository {
  constructor(
    private readonly firestore: FirestoreLike,
    // SM-RL1 — only the new rejected_retryable backoff/budget check reads
    // this; every pre-existing method here is untouched and keeps using
    // real time directly. Defaults to real time, so every existing call
    // site (Coffee/Palm included) is byte-for-byte unaffected; tests can
    // inject a fake clock to deterministically exercise backoff windows.
    private readonly clock: ServerClock = systemClock(),
  ) {}
  private ref(id: string) { return this.firestore.collection('readingProviderStages').doc(id); }
  async get(id: string): Promise<ProviderStageRecord> {
    const data = (await this.ref(id).get()).data();
    if (!data) return { state: 'not_started' };
    const state = data.state;
    if (!isKnownState(state)) return { state: 'not_started' };
    return {
      state,
      output: data.output as Record<string, unknown> | undefined,
      attemptId: data.attemptId as string | undefined,
      startedAtMs: data.startedAtMs as number | undefined,
      generationTrace: parseTrace(data.generationTrace),
      attemptCount: typeof data.attemptCount === 'number' ? data.attemptCount : undefined,
      maxAttempts: typeof data.maxAttempts === 'number' ? data.maxAttempts : undefined,
      providerErrorCode: typeof data.providerErrorCode === 'string' ? data.providerErrorCode : undefined,
      requestId: typeof data.requestId === 'string' ? data.requestId : undefined,
      rateLimit: isStringRecord(data.rateLimit) ? data.rateLimit : undefined,
      providerMessage: typeof data.providerMessage === 'string' ? data.providerMessage : undefined,
      rawRetryAfterMs: typeof data.rawRetryAfterMs === 'number' ? data.rawRetryAfterMs : undefined,
    };
  }
  async claimAttempt(id: string, ownerUserId: string, generationTrace?: ReadingGenerationTrace): Promise<ProviderStageClaim> {
    const ref = this.ref(id);
    return this.firestore.runTransaction(async tx => {
      const current = await tx.get(ref); const data = current.data();
      if (data?.state === 'provider_completed' || data?.state === 'persisted') return { state: data.state, output: data.output as Record<string, unknown> | undefined, generationTrace: parseTrace(data.generationTrace), initiate: false };
      if (data?.state === 'provider_outcome_unknown') return { state: 'provider_outcome_unknown', generationTrace: parseTrace(data.generationTrace), initiate: false };
      // SM-RL1 — a permanently blocked definitive rejection. Never retried,
      // regardless of how many more times a task/claim is redelivered.
      if (data?.state === 'rejected_terminal') {
        return {
          state: 'rejected_terminal',
          attemptId: data.attemptId as string | undefined,
          providerErrorCode: data.providerErrorCode as string | undefined,
          generationTrace: parseTrace(data.generationTrace),
          initiate: false,
        };
      }
      // SM-RL1 — a definitive but RETRYABLE rejection (e.g. rate limit).
      // Bounded by both an explicit attempt budget and a not-before time,
      // both set by markRejected() at rejection time — never by the
      // caller here, so this can never be looser than what the worker
      // itself decided when it classified the failure.
      if (data?.state === 'rejected_retryable') {
        const now = toEpochMs(this.clock.now());
        const attemptCount = typeof data.attemptCount === 'number' ? data.attemptCount : 1;
        const maxAttempts = typeof data.maxAttempts === 'number' ? data.maxAttempts : attemptCount;
        const retryNotBeforeMs = typeof data.retryNotBeforeMs === 'number' ? data.retryNotBeforeMs : 0;
        const budgetExhausted = attemptCount >= maxAttempts;
        if (budgetExhausted || now < retryNotBeforeMs) {
          return {
            state: 'rejected_retryable',
            attemptId: data.attemptId as string | undefined,
            attemptCount,
            maxAttempts,
            providerErrorCode: data.providerErrorCode as string | undefined,
            generationTrace: parseTrace(data.generationTrace),
            initiate: false,
            budgetExhausted,
          };
        }
        const nextAttempt = attemptCount + 1;
        const attemptId = `${id}:provider:${nextAttempt}`;
        const startedAtMs = now;
        const trace = generationTrace ?? parseTrace(data.generationTrace);
        tx.set(ref, {
          ...data,
          state: 'in_flight',
          attemptId,
          attemptCount: nextAttempt,
          maxAttempts,
          startedAtMs,
          updatedAtMs: startedAtMs,
          generationTrace: trace,
          expiresAt: Timestamp.fromMillis(startedAtMs + 7 * 86_400_000),
        });
        return { state: 'in_flight', attemptId, attemptCount: nextAttempt, maxAttempts, startedAtMs, generationTrace: trace, initiate: true };
      }
      if (data?.state === 'in_flight') {
        const now = Date.now();
        tx.set(ref, { ...data, state: 'provider_outcome_unknown', updatedAtMs: now, expiresAt: Timestamp.fromMillis(now + 7 * 86_400_000) });
        return { state: 'provider_outcome_unknown', attemptId: data.attemptId as string | undefined, generationTrace: parseTrace(data.generationTrace), initiate: false };
      }
      const attemptId = `${id}:provider:1`; const startedAtMs = Date.now();
      tx.set(ref, { operationId: id, ownerUserId, state: 'in_flight', attemptId, attemptCount: 1, startedAtMs, updatedAtMs: startedAtMs, generationTrace, expiresAt: Timestamp.fromMillis(startedAtMs + 7 * 86_400_000) });
      return { state: 'in_flight', attemptId, attemptCount: 1, startedAtMs, generationTrace, initiate: true };
    });
  }
  async markInFlight(id: string, ownerUserId: string): Promise<void> {
    await this.firestore.runTransaction(async tx => {
      const ref = this.ref(id); const current = await tx.get(ref);
      if (current.data()?.state === 'provider_completed' || current.data()?.state === 'persisted') return;
      tx.set(ref, { operationId: id, ownerUserId, state: 'in_flight', updatedAtMs: Date.now() });
    });
  }
  async markCompleted(id: string, ownerUserId: string, output: Record<string, unknown>): Promise<void> {
    assertCompactProviderCheckpoint(output);
    await this.firestore.runTransaction(async tx => {
      const ref = this.ref(id); const current = await tx.get(ref); const now = Date.now();
      tx.set(ref, { ...current.data(), operationId: id, ownerUserId, state: 'provider_completed', output, updatedAtMs: now, expiresAt: Timestamp.fromMillis(now + 30 * 86_400_000) });
    });
  }
  async markPersisted(id: string): Promise<void> {
    await this.firestore.runTransaction(async tx => {
      const ref = this.ref(id); const current = await tx.get(ref);
      if (!current.exists) return;
      const now = Date.now();
      tx.set(ref, { ...current.data(), state: 'persisted', updatedAtMs: now, expiresAt: Timestamp.fromMillis(now + 30 * 86_400_000) });
    });
  }
  async markOutcomeUnknown(id: string): Promise<void> {
    await this.firestore.runTransaction(async tx => {
      const ref = this.ref(id); const current = await tx.get(ref);
      if (!current.exists || current.data()?.state === 'provider_completed' || current.data()?.state === 'persisted') return;
      const now = Date.now();
      tx.set(ref, { ...current.data(), state: 'provider_outcome_unknown', updatedAtMs: now, expiresAt: Timestamp.fromMillis(now + 7 * 86_400_000) });
    });
  }
  async markRejected(id: string, ownerUserId: string, info: ProviderRejectionInfo): Promise<void> {
    void ownerUserId;
    await this.firestore.runTransaction(async tx => {
      const ref = this.ref(id); const current = await tx.get(ref);
      // Only the attempt that is actually in flight may be resolved this
      // way — a checkpoint already completed/persisted/rejected/unknown
      // by a concurrent path is left untouched (this is a no-op, not an
      // error: it means someone else already resolved it).
      if (!current.exists || current.data()?.state !== 'in_flight') return;
      const now = toEpochMs(this.clock.now());
      const state: ProviderStageState = info.retryable ? 'rejected_retryable' : 'rejected_terminal';
      const ttlMs = info.retryable ? 7 * 86_400_000 : 30 * 86_400_000;
      tx.set(ref, {
        ...current.data(),
        state,
        providerErrorCode: info.providerErrorCode,
        ...(info.requestId != null ? { requestId: info.requestId } : {}),
        ...(info.rateLimit != null ? { rateLimit: info.rateLimit } : {}),
        ...(info.providerMessage != null ? { providerMessage: info.providerMessage } : {}),
        ...(info.rawRetryAfterMs != null ? { rawRetryAfterMs: info.rawRetryAfterMs } : {}),
        ...(info.retryable
          ? {
              retryNotBeforeMs: now + Math.max(0, info.retryAfterMs ?? 0),
              maxAttempts: info.maxAttempts ?? current.data()?.attemptCount ?? 1,
            }
          : {}),
        updatedAtMs: now,
        expiresAt: Timestamp.fromMillis(now + ttlMs),
      });
    });
  }
}

function isKnownState(value: unknown): value is ProviderStageState {
  return (
    value === 'in_flight' ||
    value === 'provider_completed' ||
    value === 'persisted' ||
    value === 'provider_outcome_unknown' ||
    value === 'rejected_retryable' ||
    value === 'rejected_terminal'
  );
}

function isStringRecord(value: unknown): value is Record<string, string> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return false;
  return Object.values(value as Record<string, unknown>).every((v) => typeof v === 'string');
}

function parseTrace(value: unknown): ReadingGenerationTrace | undefined {
  if (!value || typeof value !== 'object') return undefined;
  const trace = value as Record<string, unknown>;
  return typeof trace.pipelineVersion === 'string' &&
    typeof trace.interpretationContractVersion === 'string' &&
    typeof trace.promptRulesVersion === 'string' &&
    typeof trace.modelIdentifier === 'string'
    ? trace as ReadingGenerationTrace
    : undefined;
}
