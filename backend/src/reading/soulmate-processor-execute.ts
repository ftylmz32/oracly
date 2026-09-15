/**
 * SMD1 — server-authoritative Soulmate durable execution. Mirrors
 * `reading-processor-execute.ts`'s structure (claim -> provider ->
 * checkpoint -> persist -> complete -> notify) but Soulmate has no staged
 * input IMAGE (its input is the structured name/birth/gender/intention
 * record already saved via `ReadingOperationInputService`) and needs TWO
 * independently checkpointed provider stages — portrait, then
 * interpretation — instead of Coffee/Palm's single vision call.
 *
 * Only ever invoked for an operation whose `executionMode === 'durable'`
 * (enforced one layer up, in `ReadingProcessor`) — a legacy client-driven
 * Soulmate operation never reaches this function.
 */
import type { SoulmateIdentity } from '../ai/soulmate-prompt.js';
import { magicMatches } from '../ai/image.js';
import { createHash } from 'node:crypto';
import type { ValidatedRequest } from '../ai/validate-request.js';
import type { ServerClock } from './clock.js';
import { toEpochMs } from './clock.js';
import type { ReadingFlow } from './reading-flow.js';
import type { ReadingCompletionNotifier } from './reading-processor.js';
import type { ReadingResultRepository } from './reading-result-repository.js';
import type { ReadingLanguage } from './operation-model.js';
import type { ReadingOperationInputService } from './operation-input-service.js';
import type { SoulmatePortraitStore } from './soulmate-portrait-store.js';
import type { SoulmateEntitlementGuard } from './soulmate-entitlement-guard.js';
import type {
  ProviderStageRepository,
  ReadingGenerationTrace,
} from './provider-stage-repository.js';
import {
  logWorkerStage,
  wrapStageError,
  type WorkerStageLogger,
} from './reading-worker-telemetry.js';
import { classifyProviderFailure } from './soulmate-provider-failure.js';

/** SM-RL1 §3 — conservative default; no existing project standard found. */
const SOULMATE_PORTRAIT_MAX_ATTEMPTS = 3;

/** SM-RL2 §4 — SM-PR1 found the prior flat 2s fallback let all 3 attempts
 * of a real incident land inside a 13.3s span, almost certainly the same
 * short rate-limit window. These floors are a MINIMUM wait before the
 * next attempt is eligible when the provider gives no (or a shorter)
 * Retry-After — indexed by the attempt number that was just rejected.
 * Soulmate-portrait-only: Coffee/Palm/the generic `runProviderStage` never
 * call this (SM-RL2 §10). */
const RATE_LIMIT_FALLBACK_FLOOR_MS_BY_ATTEMPT: Readonly<Record<number, number>> = {
  1: 30_000,
  2: 60_000,
};
/** Sane upper bound guarding only against a corrupt/absurd provider
 * Retry-After value — never used to shorten a legitimate longer one.
 * Cloud Tasks' own queue (maxBackoff 3600s) has no trouble waiting this
 * long, so this exists purely as a safety ceiling. */
const RATE_LIMIT_MAX_BACKOFF_MS = 10 * 60_000;

function rateLimitFallbackFloorMs(attemptJustRejected: number): number {
  return (
    RATE_LIMIT_FALLBACK_FLOOR_MS_BY_ATTEMPT[attemptJustRejected] ??
    RATE_LIMIT_FALLBACK_FLOOR_MS_BY_ATTEMPT[2]
  );
}

/** The provider's own Retry-After always wins when it asks for LONGER than
 * our floor; our floor only fills in when Retry-After is absent or would
 * itself be too short for the attempt that was just rejected. */
function computeRateLimitBackoffMs(
  attemptJustRejected: number,
  retryAfterMs: number | undefined,
): number {
  const floor = rateLimitFallbackFloorMs(attemptJustRejected);
  const chosen = retryAfterMs != null && retryAfterMs > floor ? retryAfterMs : floor;
  return Math.min(Math.round(chosen), RATE_LIMIT_MAX_BACKOFF_MS);
}

type ClaimedSoulmateOp = {
  operationId: string;
  ownerUserId: string;
  language: ReadingLanguage;
};

type AiHandle = {
  handle(
    request: ValidatedRequest,
    modelHint: unknown,
    context: { identity: string; parentKey: string },
  ): Promise<Record<string, unknown>>;
};

const FEATURE = 'soulmate' as const;

function portraitStageId(operationId: string): string {
  return `${operationId}:portrait`;
}

function interpretationStageId(operationId: string): string {
  return `${operationId}:interpretation`;
}

export async function executeClaimedSoulmateReading(input: {
  operation: ClaimedSoulmateOp;
  log: WorkerStageLogger;
  inputs: ReadingOperationInputService;
  portraits: SoulmatePortraitStore;
  results: ReadingResultRepository;
  flow: ReadingFlow;
  ai: AiHandle;
  clock: ServerClock;
  notifier: ReadingCompletionNotifier;
  providerStages: ProviderStageRepository;
  entitlement: SoulmateEntitlementGuard;
  generationTrace?: ReadingGenerationTrace;
  /** SM-RL2 §3 — for the `provider_rate_limited` observability log only;
   * never affects behavior. */
  imageModel?: string;
}): Promise<'completed' | 'failed'> {
  const { operation, log } = input;
  const operationId = operation.operationId;
  try {
    // SMD1 §7 — authoritative, server-side, checked BEFORE any paid call.
    const premium = await input.entitlement.isPremiumActive(operation.ownerUserId);
    if (!premium) {
      log.error({ event: 'soulmate_entitlement_denied', operationId, feature: FEATURE });
      await input.flow.failFinal({
        ownerUserId: operation.ownerUserId,
        operationId,
        failureCode: 'entitlement_denied',
      });
      return 'failed';
    }
    logWorkerStage(log, 'soulmate_input_load_started', { operationId, feature: FEATURE });
    const loaded = await input.inputs.get(operation.ownerUserId, operationId);
    // `sanitizeSoulmateFields` already refuses to persist an input record
    // missing `name`/a valid `birthIso` (operation-input-model.ts) — this
    // is a defensive re-check, not the primary validation.
    if (!loaded || !loaded.name || !loaded.birthIso) {
      throw wrapStageError(
        'soulmate_input_load_started',
        FEATURE,
        new Error('soulmate_input_unavailable'),
        true,
      );
    }
    const fields = { name: loaded.name, birthIso: loaded.birthIso, gender: loaded.gender, intention: loaded.intention };
    const gender = fields.gender === 'feminine' || fields.gender === 'masculine' ? fields.gender : undefined;
    logWorkerStage(log, 'soulmate_input_load_succeeded', { operationId, feature: FEATURE });

    // --- Stage 1: portrait -------------------------------------------------
    const portraitOutput = await runPortraitProviderStage({
      stageId: portraitStageId(operationId),
      operation,
      log,
      ai: input.ai,
      portraits: input.portraits,
      providerStages: input.providerStages,
      flow: input.flow,
      generationTrace: input.generationTrace,
      imageModel: input.imageModel,
      buildRequest: () => ({
        operation: 'soulmate_draw',
        name: fields.name,
        birthDate: fields.birthIso,
        gender,
        intention: fields.intention,
        language: operation.language,
      }),
    });
    if (portraitOutput.outcome !== 'ok') return portraitOutput.outcome;
    const identity = portraitOutput.data.identity;

    // --- Stage 2: interpretation --------------------------------------------
    const interpretationOutput = await runProviderStage({
      stageId: interpretationStageId(operationId),
      operation,
      log,
      ai: input.ai,
      providerStages: input.providerStages,
      flow: input.flow,
      generationTrace: input.generationTrace,
      // Personal-memory personalization is client-local infrastructure
      // with no server-side equivalent today — `memorySummary` is omitted
      // rather than invented. Creative substance (archetype/visual
      // identity) is unaffected; see SMD1 final report.
      buildRequest: () => ({
        operation: 'soulmate_interpretation',
        name: fields.name,
        birthDate: fields.birthIso,
        gender,
        intention: fields.intention,
        identity: identity as SoulmateIdentity | undefined,
        language: operation.language,
      }),
    });
    if (interpretationOutput.outcome !== 'ok') return interpretationOutput.outcome;

    const nowMs = toEpochMs(input.clock.now());
    const resultId = `soulmate_${operationId}`;
    logWorkerStage(log, 'result_persist_started', { operationId, feature: FEATURE });
    let result: { resultId: string };
    try {
      result = await input.results.persistOnce({
        schemaVersion: 1,
        operationId,
        ownerUserId: operation.ownerUserId,
        readingType: 'soulmate',
        resultId,
        data: {
          // Same 6-field shape ai/service.ts's soulmateInterpretation()
          // returns and the client's own proxy_soul_mate_interpretation.dart
          // already maps 1:1 (energy=personality, dynamics=dynamic,
          // yourSide=challenge) — persist all of it, not a subset.
          personality: interpretationOutput.data.personality,
          dynamic: interpretationOutput.data.dynamic,
          attraction: interpretationOutput.data.attraction,
          challenge: interpretationOutput.data.challenge,
          meeting: interpretationOutput.data.meeting,
          feeling: interpretationOutput.data.feeling,
          identity,
          portraitAvailable: true,
        },
        persistedAtMs: nowMs,
        notificationSentAtMs: null,
        generationTrace: input.generationTrace,
      });
      await input.flow.complete({
        ownerUserId: operation.ownerUserId,
        operationId,
        resultId: result.resultId,
      });
      await input.providerStages.markPersisted(interpretationStageId(operationId));
    } catch (error) {
      throw wrapStageError('result_persist_started', FEATURE, error, true);
    }
    logWorkerStage(log, 'result_persist_completed', { operationId, feature: FEATURE });

    logWorkerStage(log, 'notification_started', { operationId, feature: FEATURE });
    try {
      // R2.1 — at-most-once: claim the right to dispatch BEFORE any FCM
      // call. A redelivered/concurrent invocation observing an existing
      // claim (whatever its outcome) must never call the provider again.
      const claim = await input.results.claimNotificationDispatch(operationId, nowMs);
      if (claim === 'claimed') {
        try {
          await input.notifier.notifyCompleted({
            operationId,
            ownerUserId: operation.ownerUserId,
            readingType: 'soulmate',
          });
          await input.results.markNotificationSent(operationId, nowMs);
          logWorkerStage(log, 'notification_completed', { operationId, feature: FEATURE });
        } catch (error) {
          log.error({
            event: 'notification_send_failed',
            operationId,
            feature: FEATURE,
            errorCode: error instanceof Error ? error.name.slice(0, 80) : 'notification_error',
          });
          // Push failure must never fail an already-persisted reading. The
          // claim above already prevents any later redelivery from
          // retrying this user-visible send, ambiguous or not.
        }
      } else {
        logWorkerStage(log, 'notification_already_dispatched', { operationId, feature: FEATURE });
      }
    } catch (error) {
      log.error({
        event: 'notification_claim_failed',
        operationId,
        feature: FEATURE,
        errorCode: error instanceof Error ? error.name.slice(0, 80) : 'notification_claim_error',
      });
      // Claim-transaction failure must never fail an already-persisted reading either.
    }
    return 'completed';
  } catch (error) {
    try {
      await input.flow.releaseClaim(operation.ownerUserId, operationId);
    } catch {
      // Lease release is best-effort; the original failure still drives retry.
    }
    throw wrapStageError('worker', FEATURE, error, true);
  }
}

type ProviderStageOutcome =
  | { outcome: 'ok'; data: Record<string, unknown> }
  | { outcome: 'failed' };

type PortraitCheckpoint = {
  operation: 'soulmate_draw';
  artifact: { contentType: string; byteSize: number; sha256: string };
  identity: SoulmateIdentity;
};

async function runPortraitProviderStage(input: {
  stageId: string;
  operation: ClaimedSoulmateOp;
  log: WorkerStageLogger;
  ai: AiHandle;
  portraits: SoulmatePortraitStore;
  providerStages: ProviderStageRepository;
  flow: ReadingFlow;
  generationTrace?: ReadingGenerationTrace;
  imageModel?: string;
  buildRequest: () => ValidatedRequest;
}): Promise<ProviderStageOutcome> {
  logWorkerStage(input.log, 'provider_started', {
    operationId: input.operation.operationId,
    feature: `${FEATURE}:${input.stageId}`,
  });
  try {
    // Recovery is deliberately before claimAttempt(): an object may already
    // be durable while the compact Firestore checkpoint write was interrupted.
    const recovered = await input.portraits.get(
      input.operation.operationId,
      input.operation.ownerUserId,
    );
    if (recovered) {
      const checkpoint = portraitCheckpoint(recovered);
      await input.providerStages.markCompleted(
        input.stageId,
        input.operation.ownerUserId,
        checkpoint,
      );
      await input.providerStages.markPersisted(input.stageId);
      return { outcome: 'ok', data: checkpoint };
    }

    const claim = await input.providerStages.claimAttempt(
      input.stageId,
      input.operation.ownerUserId,
      input.generationTrace,
    );
    if (claim.state === 'provider_outcome_unknown') {
      input.log.error({
        event: 'provider_outcome_unknown',
        operationId: input.operation.operationId,
        feature: FEATURE,
        stageId: input.stageId,
        attemptId: claim.attemptId,
      });
      await input.flow.failFinal({
        ownerUserId: input.operation.ownerUserId,
        operationId: input.operation.operationId,
        failureCode: 'unavailable',
      });
      return { outcome: 'failed' };
    }
    // SM-RL1 — a definitive, KNOWN-no-output rejection, never confusable
    // with the ambiguous case above: no more retries are possible, ever.
    if (claim.state === 'rejected_terminal') {
      input.log.error({
        event: 'provider_rejected_terminal',
        operationId: input.operation.operationId,
        feature: FEATURE,
        stageId: input.stageId,
        providerErrorCode: claim.providerErrorCode,
      });
      await input.flow.failFinal({
        ownerUserId: input.operation.ownerUserId,
        operationId: input.operation.operationId,
        failureCode: 'invalid',
      });
      return { outcome: 'failed' };
    }
    // SM-RL1 — a definitive, KNOWN-no-output rejection that IS eligible
    // for a bounded retry, but not from THIS claim (budget spent, or the
    // backoff window hasn't elapsed yet).
    if (claim.state === 'rejected_retryable' && !claim.initiate) {
      if (claim.budgetExhausted) {
        input.log.error({
          event: 'provider_retry_budget_exhausted',
          operationId: input.operation.operationId,
          feature: FEATURE,
          stageId: input.stageId,
          attemptCount: claim.attemptCount,
          maxAttempts: claim.maxAttempts,
        });
        await input.flow.failFinal({
          ownerUserId: input.operation.ownerUserId,
          operationId: input.operation.operationId,
          failureCode: 'unavailable',
        });
        return { outcome: 'failed' };
      }
      input.log.error({
        event: 'provider_retry_scheduled',
        operationId: input.operation.operationId,
        feature: FEATURE,
        stageId: input.stageId,
        attemptCount: claim.attemptCount,
      });
      // Retryable, non-terminal HTTP failure — Cloud Tasks redelivers the
      // task later; the NEXT claim re-evaluates the backoff window fresh.
      throw wrapStageError(
        'provider_started',
        FEATURE,
        new Error('provider_retry_not_yet_due'),
        true,
      );
    }
    if (claim.state === 'provider_completed' || claim.state === 'persisted') {
      throw new Error('soulmate_portrait_artifact_unavailable');
    }
    if (!claim.initiate) throw new Error('provider_stage_not_initiable');

    let raw: Record<string, unknown>;
    try {
      raw = await input.ai.handle(input.buildRequest(), undefined, {
        identity: input.operation.ownerUserId,
        parentKey: `reading-operation:${input.operation.operationId}`,
      });
    } catch (error) {
      const classified = classifyProviderFailure(error);
      // Truly ambiguous outcomes are NEVER reclassified here — same
      // fail-closed path as before, unchanged (SM-RL1 §5 / SM-RL2 §7).
      if (classified.kind === 'ambiguous_transport_outcome') throw error;
      const retryable = classified.kind === 'definitive_retryable_rejection';
      const attemptJustRejected = claim.attemptCount ?? 1;
      const backoffMs = retryable
        ? computeRateLimitBackoffMs(attemptJustRejected, classified.retryAfterMs)
        : 0;
      await input.providerStages.markRejected(
        input.stageId,
        input.operation.ownerUserId,
        {
          retryable,
          providerErrorCode: classified.providerErrorCode,
          ...(retryable
            ? { retryAfterMs: backoffMs, maxAttempts: SOULMATE_PORTRAIT_MAX_ATTEMPTS }
            : {}),
          // SM-RL2 §5 — durably persisted on the checkpoint itself, not
          // only logged, so a future forensic pass is never blocked the
          // way SM-PR1 was.
          ...(classified.requestId != null ? { requestId: classified.requestId } : {}),
          ...(classified.rateLimit != null ? { rateLimit: classified.rateLimit } : {}),
          ...(classified.providerMessage != null
            ? { providerMessage: classified.providerMessage }
            : {}),
          ...(classified.retryAfterMs != null ? { rawRetryAfterMs: classified.retryAfterMs } : {}),
        },
      );
      if (retryable) {
        // SM-RL2 §3 — the structured evidence a live 429 needs so the
        // NEXT rate-limit incident is diagnosable without another
        // forensic blind spot (SM-PR1).
        input.log.error({
          event: 'provider_rate_limited',
          operationId: input.operation.operationId,
          feature: FEATURE,
          stageId: input.stageId,
          operationType: 'soulmate_draw',
          model: input.imageModel,
          attempt: attemptJustRejected,
          maxAttempts: SOULMATE_PORTRAIT_MAX_ATTEMPTS,
          httpStatus: 429,
          retryAfterMs: classified.retryAfterMs,
          requestId: classified.requestId,
          rateLimit: classified.rateLimit,
          providerMessage: classified.providerMessage,
          chosenRetryDelayMs: backoffMs,
          retryBudgetRemaining: attemptJustRejected < SOULMATE_PORTRAIT_MAX_ATTEMPTS,
        });
        input.log.error({
          event: 'provider_rejected_retryable',
          operationId: input.operation.operationId,
          feature: FEATURE,
          stageId: input.stageId,
          providerErrorCode: classified.providerErrorCode,
        });
        throw wrapStageError('provider_started', FEATURE, error, true);
      }
      input.log.error({
        event: 'provider_rejected_terminal',
        operationId: input.operation.operationId,
        feature: FEATURE,
        stageId: input.stageId,
        providerErrorCode: classified.providerErrorCode,
      });
      await input.flow.failFinal({
        ownerUserId: input.operation.ownerUserId,
        operationId: input.operation.operationId,
        failureCode: 'invalid',
      });
      return { outcome: 'failed' };
    }
    const imageBase64 = raw.imageBase64;
    const identity = raw.identity;
    if (typeof imageBase64 !== 'string' || !identity || typeof identity !== 'object') {
      throw new Error('soulmate_portrait_response_invalid');
    }
    const decoded = decodePortrait(imageBase64);
    logWorkerStage(input.log, 'soulmate_portrait_persist_started', {
      operationId: input.operation.operationId,
      feature: FEATURE,
    });
    await input.portraits.put({
      operationId: input.operation.operationId,
      ownerUserId: input.operation.ownerUserId,
      bytes: decoded.bytes,
      contentType: decoded.contentType,
      identity: identity as SoulmateIdentity,
    });
    const verified = await input.portraits.get(
      input.operation.operationId,
      input.operation.ownerUserId,
    );
    if (!verified) throw new Error('soulmate_portrait_verification_failed');
    const checkpoint = portraitCheckpoint(verified);
    await input.providerStages.markCompleted(
      input.stageId,
      input.operation.ownerUserId,
      checkpoint,
    );
    await input.providerStages.markPersisted(input.stageId);
    logWorkerStage(input.log, 'soulmate_portrait_persist_completed', {
      operationId: input.operation.operationId,
      feature: FEATURE,
    });
    logWorkerStage(input.log, 'provider_completed', {
      operationId: input.operation.operationId,
      feature: `${FEATURE}:${input.stageId}`,
    });
    return { outcome: 'ok', data: checkpoint };
  } catch (error) {
    throw wrapStageError('provider_started', FEATURE, error, true);
  }
}

function portraitCheckpoint(portrait: Awaited<ReturnType<SoulmatePortraitStore['get']>> & {}): PortraitCheckpoint {
  return {
    operation: 'soulmate_draw',
    artifact: {
      contentType: portrait.contentType,
      byteSize: portrait.byteSize,
      sha256: portrait.sha256,
    },
    identity: portrait.identity,
  };
}

function decodePortrait(imageBase64: string): { bytes: Buffer; contentType: string } {
  const encoded = imageBase64.trim();
  if (!encoded || encoded.length % 4 !== 0 || !/^[A-Za-z0-9+/]+={0,2}$/.test(encoded)) {
    throw new Error('soulmate_portrait_response_invalid');
  }
  const bytes = Buffer.from(encoded, 'base64');
  if (bytes.length < 32 || bytes.length > 20 * 1024 * 1024) {
    throw new Error('soulmate_portrait_response_invalid');
  }
  const contentType = magicMatches(bytes, 'image/png') ? 'image/png'
    : magicMatches(bytes, 'image/jpeg') ? 'image/jpeg'
      : magicMatches(bytes, 'image/webp') ? 'image/webp'
        : null;
  if (!contentType) throw new Error('soulmate_portrait_response_invalid');
  // Hashing here ensures decoding completed before any durable write; the
  // store independently hashes and verifies the bytes after retrieval.
  createHash('sha256').update(bytes).digest('hex');
  return { bytes, contentType };
}

/**
 * One checkpointed provider call. Exactly mirrors the accepted Coffee/Palm
 * contract in `reading-processor-execute.ts`: reuse persisted output on a
 * `provider_completed`/`persisted` replay, never re-call on
 * `provider_outcome_unknown` (fail closed with a refund instead).
 */
async function runProviderStage(input: {
  stageId: string;
  operation: ClaimedSoulmateOp;
  log: WorkerStageLogger;
  ai: AiHandle;
  providerStages: ProviderStageRepository;
  flow: ReadingFlow;
  generationTrace?: ReadingGenerationTrace;
  buildRequest: () => ValidatedRequest;
}): Promise<ProviderStageOutcome> {
  logWorkerStage(input.log, 'provider_started', {
    operationId: input.operation.operationId,
    feature: `${FEATURE}:${input.stageId}`,
  });
  try {
    const checkpoint = await input.providerStages.claimAttempt(
      input.stageId,
      input.operation.ownerUserId,
      input.generationTrace,
    );
    if (checkpoint.state === 'provider_outcome_unknown') {
      input.log.error({
        event: 'provider_outcome_unknown',
        operationId: input.operation.operationId,
        feature: FEATURE,
        stageId: input.stageId,
        attemptId: checkpoint.attemptId,
      });
      await input.flow.failFinal({
        ownerUserId: input.operation.ownerUserId,
        operationId: input.operation.operationId,
        failureCode: 'unavailable',
      });
      return { outcome: 'failed' };
    }
    if (
      (checkpoint.state === 'provider_completed' || checkpoint.state === 'persisted') &&
      checkpoint.output
    ) {
      return { outcome: 'ok', data: checkpoint.output };
    }
    if (!checkpoint.initiate) {
      throw new Error('provider_stage_not_initiable');
    }
    const data = await input.ai.handle(
      input.buildRequest(),
      undefined,
      {
        identity: input.operation.ownerUserId,
        parentKey: `reading-operation:${input.operation.operationId}`,
      },
    );
    await input.providerStages.markCompleted(
      input.stageId,
      input.operation.ownerUserId,
      data,
    );
    logWorkerStage(input.log, 'provider_completed', {
      operationId: input.operation.operationId,
      feature: `${FEATURE}:${input.stageId}`,
    });
    return { outcome: 'ok', data };
  } catch (error) {
    throw wrapStageError('provider_started', FEATURE, error, true);
  }
}
