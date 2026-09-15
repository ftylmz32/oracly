import { createHash } from 'node:crypto';
import type { ValidatedRequest } from '../ai/validate-request.js';
import type { ServerClock } from './clock.js';
import { toEpochMs } from './clock.js';
import type { ReadingStagedImageRepository } from './operation-staged-image-repository.js';
import type { ReadingStagedImageService } from './operation-staged-image-service.js';
import type { ReadingFlow } from './reading-flow.js';
import type { ReadingCompletionNotifier } from './reading-processor.js';
import type { ReadingResultRepository } from './reading-result-repository.js';
import type { ReadingLanguage } from './operation-model.js';
import type { ProviderStageRepository } from './provider-stage-repository.js';
import type { ReadingGenerationTrace } from './provider-stage-repository.js';
import {
  logWorkerStage,
  wrapStageError,
  type WorkerStageLogger,
} from './reading-worker-telemetry.js';

type ClaimedOp = {
  operationId: string;
  ownerUserId: string;
  readingType: 'coffee' | 'palm';
  language: ReadingLanguage;
};

type AiHandle = {
  handle(
    request: ValidatedRequest,
    modelHint: unknown,
    context: { identity: string; parentKey: string },
  ): Promise<Record<string, unknown>>;
};

export async function executeClaimedReading(input: {
  operation: ClaimedOp;
  log: WorkerStageLogger;
  stagedRepository: ReadingStagedImageRepository;
  stagedImages: ReadingStagedImageService;
  results: ReadingResultRepository;
  flow: ReadingFlow;
  ai: AiHandle;
  clock: ServerClock;
  notifier: ReadingCompletionNotifier;
  stopAfterStaged: boolean;
  providerStages?: ProviderStageRepository;
  generationTrace?: ReadingGenerationTrace;
}): Promise<'completed' | 'staged_ok' | 'failed'> {
  const { operation, log } = input;
  const feature = operation.readingType;
  const operationId = operation.operationId;
  try {
    logWorkerStage(log, 'staged_fetch_started', { operationId, feature });
    // Coffee V2 slotted staging — selection rule: if ANY of the three
    // canonical slots exists for this Coffee operation, it is a V2 input
    // and requires the complete set (Phase 2A). Missing/incomplete slots
    // are a retryable "staging not ready" condition — never a terminal
    // failure, never an AI call. Palm always uses the legacy branch below
    // (no slot record can ever exist for Palm — `stage()` fails closed
    // before one could be written). A complete V2 set is handled entirely
    // here — it never falls through to the legacy single-image fetch
    // below (Phase 2B).
    const isCoffeeV2 =
      feature === 'coffee' &&
      (await input.stagedImages.hasAnyCoffeeV2Slot({
        ownerUserId: operation.ownerUserId,
        operationId,
      }));

    let providerPayload: Record<string, unknown>;
    let resultExtra: Record<string, unknown> = {};
    let cleanupAfterSuccess: () => Promise<void>;

    if (isCoffeeV2) {
      let v2Images: Array<{ slot: string; bytes: Buffer; mimeType: string }>;
      try {
        v2Images = await input.stagedImages.retrieveCoffeeV2ForProcessing({
          ownerUserId: operation.ownerUserId,
          operationId,
        });
      } catch (error) {
        throw wrapStageError('staged_fetch_started', feature, error, true);
      }
      logWorkerStage(log, 'staged_fetch_succeeded', {
        operationId,
        feature,
        byteLength: v2Images.reduce((sum, image) => sum + image.bytes.length, 0),
      });
      if (input.stopAfterStaged) return 'staged_ok';
      // No mimeType/hand needed here — the Coffee V2 analysis handler
      // re-derives everything it needs from operationId via the SAME
      // staging service, exactly like the legacy handler already does.
      providerPayload = { operationId };
      cleanupAfterSuccess = () =>
        input.stagedImages.deleteCoffeeV2Slots({
          ownerUserId: operation.ownerUserId,
          operationId,
        });
    } else {
      const staged = await input.stagedRepository.get(operationId, operation.ownerUserId);
      if (!staged || staged.uploadState !== 'complete') {
        throw wrapStageError(
          'staged_fetch_started',
          feature,
          new Error('staged_input_unavailable'),
          true,
        );
      }
      let fetched: { bytes: Buffer };
      try {
        fetched = await input.stagedImages.retrieveForProcessing({
          ownerUserId: operation.ownerUserId,
          operationId,
          readingType: operation.readingType,
        });
      } catch (error) {
        throw wrapStageError('staged_fetch_started', feature, error, true);
      }
      const checksumMatched =
        createHash('sha256').update(fetched.bytes).digest('hex') === staged.checksumSha256;
      logWorkerStage(log, 'staged_fetch_succeeded', {
        operationId,
        feature,
        byteLength: fetched.bytes.length,
        checksumMatched,
      });
      if (input.stopAfterStaged) return 'staged_ok';
      providerPayload = {
        operationId,
        mimeType: staged.contentType,
        ...(feature === 'palm' ? { hand: staged.handSide ?? 'right' } : {}),
      };
      if (feature === 'palm') resultExtra = { _handSide: staged.handSide ?? 'right' };
      cleanupAfterSuccess = () =>
        input.stagedImages.delete({ ownerUserId: operation.ownerUserId, operationId });
    }

    logWorkerStage(log, 'provider_started', { operationId, feature });
    logWorkerStage(log, 'validation_started', { operationId, feature });
    let data: Record<string, unknown>;
    let generationTrace = input.generationTrace;
    try {
      const checkpoint = input.providerStages
        ? await input.providerStages.claimAttempt(operationId, operation.ownerUserId, input.generationTrace)
        : undefined;
      generationTrace = checkpoint?.generationTrace ?? generationTrace;
      if (checkpoint?.state === 'provider_outcome_unknown') {
        log.error({ event: 'provider_outcome_unknown', operationId, feature, attemptId: checkpoint.attemptId });
        // Conservative release policy: ambiguity is terminal for this logical
        // operation. failFinal invokes the existing authoritative Gem refund.
        await input.flow.failFinal({ ownerUserId: operation.ownerUserId, operationId, failureCode: 'unavailable' });
        await cleanupAfterSuccess();
        return 'failed';
      }
      if ((checkpoint?.state === 'provider_completed' || checkpoint?.state === 'persisted') && checkpoint.output) {
        data = checkpoint.output;
      } else {
        if (checkpoint && !checkpoint.initiate) throw new Error('provider_stage_not_initiable');
        data = await input.ai.handle(
        {
          operation: `${operation.readingType}_analysis`,
          payload: providerPayload,
          language: operation.language,
        },
        undefined,
        {
          identity: operation.ownerUserId,
          parentKey: `reading-operation:${operationId}`,
        },
        );
        await input.providerStages?.markCompleted(operationId, operation.ownerUserId, data);
      }
    } catch (error) {
      throw wrapStageError('provider_started', feature, error, true);
    }
    logWorkerStage(log, 'provider_completed', { operationId, feature });
    logWorkerStage(log, 'validation_completed', { operationId, feature });

    const nowMs = toEpochMs(input.clock.now());
    const resultId = `${operation.readingType}_${operationId}`;
    logWorkerStage(log, 'result_persist_started', { operationId, feature });
    let result: { resultId: string };
    try {
      result = await input.results.persistOnce({
        schemaVersion: 1,
        operationId,
        ownerUserId: operation.ownerUserId,
        readingType: operation.readingType,
        resultId,
        data: { ...data, ...resultExtra },
        persistedAtMs: nowMs,
        notificationSentAtMs: null,
        generationTrace,
      });
      await input.flow.complete({
        ownerUserId: operation.ownerUserId,
        operationId,
        resultId: result.resultId,
      });
      await input.providerStages?.markPersisted(operationId);
    } catch (error) {
      throw wrapStageError('result_persist_started', feature, error, true);
    }
    logWorkerStage(log, 'result_persist_completed', { operationId, feature });

    logWorkerStage(log, 'notification_started', { operationId, feature });
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
            readingType: operation.readingType,
          });
          await input.results.markNotificationSent(operationId, nowMs);
          logWorkerStage(log, 'notification_completed', { operationId, feature });
        } catch (error) {
          log.error({
            event: 'notification_send_failed',
            operationId,
            feature,
            errorCode: error instanceof Error ? error.name.slice(0, 80) : 'notification_error',
          });
          // Push failure must never fail an already-persisted reading. The
          // claim above already prevents any later redelivery from
          // retrying this user-visible send, ambiguous or not.
        }
      } else {
        logWorkerStage(log, 'notification_already_dispatched', { operationId, feature });
      }
    } catch (error) {
      log.error({
        event: 'notification_claim_failed',
        operationId,
        feature,
        errorCode: error instanceof Error ? error.name.slice(0, 80) : 'notification_claim_error',
      });
      // Claim-transaction failure (e.g. a Firestore hiccup) must never
      // fail an already-persisted reading either.
    }
    // Retryable failures above never reach here — cleanup only runs after a
    // successfully persisted result, exactly like the legacy delete() call
    // it replaces/extends. Cleanup itself is best-effort (see
    // ReadingStagedImageService.deleteCoffeeV2Slots/delete).
    await cleanupAfterSuccess();
    return 'completed';
  } catch (error) {
    try {
      await input.flow.releaseClaim(operation.ownerUserId, operationId);
    } catch {
      // Lease release is best-effort; the original failure still drives retry.
    }
    throw wrapStageError('worker', feature, error, true);
  }
}
