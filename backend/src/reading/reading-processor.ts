import type { ValidatedRequest } from '../ai/validate-request.js';
import type { ServerClock } from './clock.js';
import type { ReadingOperationRepository } from './operation-repository.js';
import type { ReadingOperationInputService } from './operation-input-service.js';
import type { ReadingStagedImageRepository } from './operation-staged-image-repository.js';
import type { ReadingStagedImageService } from './operation-staged-image-service.js';
import type { ReadingFlow } from './reading-flow.js';
import { executeClaimedReading } from './reading-processor-execute.js';
import { executeClaimedSoulmateReading } from './soulmate-processor-execute.js';
import type { SoulmatePortraitStore } from './soulmate-portrait-store.js';
import type { SoulmateEntitlementGuard } from './soulmate-entitlement-guard.js';
import { ReadingResultRepository } from './reading-result-repository.js';
import {
  logWorkerStage,
  wrapStageError,
  type WorkerStageLogger,
} from './reading-worker-telemetry.js';
import type { ProviderStageRepository } from './provider-stage-repository.js';
import type { ReadingGenerationTrace } from './provider-stage-repository.js';

export type ReadingProcessOutcome = 'completed' | 'noop' | 'staged_ok' | 'failed';

export interface ReadingCompletionNotifier {
  notifyCompleted(input: {
    operationId: string;
    ownerUserId: string;
    readingType: 'coffee' | 'palm' | 'soulmate';
  }): Promise<void>;
}

export class NoopReadingCompletionNotifier implements ReadingCompletionNotifier {
  async notifyCompleted(): Promise<void> {}
}

export class ReadingProcessor {
  constructor(
    private readonly operations: ReadingOperationRepository,
    private readonly flow: ReadingFlow,
    private readonly stagedRepository: ReadingStagedImageRepository,
    private readonly stagedImages: ReadingStagedImageService,
    private readonly results: ReadingResultRepository,
    private readonly ai: {
      handle(
        request: ValidatedRequest,
        modelHint: unknown,
        context: { identity: string; parentKey: string },
      ): Promise<Record<string, unknown>>;
    },
    private readonly clock: ServerClock,
    private readonly notifier: ReadingCompletionNotifier = new NoopReadingCompletionNotifier(),
    private readonly stopAfterStaged = false,
    private readonly providerStages?: ProviderStageRepository,
    private readonly generationTrace?: ReadingGenerationTrace,
    private readonly soulmateInputs?: ReadingOperationInputService,
    private readonly soulmatePortraits?: SoulmatePortraitStore,
    private readonly soulmateEntitlement?: SoulmateEntitlementGuard,
    /** SM-RL2 §3 — for the `provider_rate_limited` observability log only;
     * never affects behavior. */
    private readonly soulmateImageModel?: string,
  ) {}

  async process(
    operationId: string,
    log: WorkerStageLogger = silentLog,
  ): Promise<ReadingProcessOutcome> {
    const operation = await this.operations.getById(operationId);
    if (!operation) return 'noop';
    if (operation.status === 'ready') return 'noop';

    // SMD1 — a Soulmate operation is only ever durably processed when the
    // client explicitly opted in at creation time (`executionMode ===
    // 'durable'`). Every pre-SMD1 (and every historical) Soulmate
    // operation has `executionMode` absent/null and falls straight
    // through to 'noop' here, exactly as before this branch existed —
    // this worker never touches a legacy client-driven operation.
    if (operation.readingType === 'soulmate') {
      if (operation.executionMode !== 'durable') return 'noop';
      if (
        !this.providerStages ||
        !this.soulmateInputs ||
        !this.soulmatePortraits ||
        !this.soulmateEntitlement
      ) {
        return 'noop';
      }
      const claimed = await this.flow.claim(operation.ownerUserId, operation.operationId);
      if (!claimed.execute) {
        if (claimed.operation.status === 'processing' && !claimed.operation.resultId) {
          throw wrapStageError(
            'reading_task_claim_acquired',
            'soulmate',
            new Error('processing_lease_active'),
            true,
          );
        }
        return 'noop';
      }
      logWorkerStage(log, 'reading_task_claim_acquired', { operationId, feature: 'soulmate' });
      return executeClaimedSoulmateReading({
        operation: {
          operationId: operation.operationId,
          ownerUserId: operation.ownerUserId,
          language: operation.language,
        },
        log,
        inputs: this.soulmateInputs,
        portraits: this.soulmatePortraits,
        results: this.results,
        flow: this.flow,
        ai: this.ai,
        clock: this.clock,
        notifier: this.notifier,
        providerStages: this.providerStages,
        entitlement: this.soulmateEntitlement,
        generationTrace: this.generationTrace,
        imageModel: this.soulmateImageModel,
      });
    }

    if (operation.readingType !== 'coffee' && operation.readingType !== 'palm') {
      return 'noop';
    }
    const feature = operation.readingType;
    const claimed = await this.flow.claim(operation.ownerUserId, operation.operationId);
    if (!claimed.execute) {
      if (claimed.operation.status === 'processing' && !claimed.operation.resultId) {
        throw wrapStageError(
          'reading_task_claim_acquired',
          feature,
          new Error('processing_lease_active'),
          true,
        );
      }
      return 'noop';
    }
    logWorkerStage(log, 'reading_task_claim_acquired', { operationId, feature });
    return executeClaimedReading({
      operation: {
        operationId: operation.operationId,
        ownerUserId: operation.ownerUserId,
        readingType: operation.readingType,
        language: operation.language,
      },
      log,
      stagedRepository: this.stagedRepository,
      stagedImages: this.stagedImages,
      results: this.results,
      flow: this.flow,
      ai: this.ai,
      clock: this.clock,
      notifier: this.notifier,
      stopAfterStaged: this.stopAfterStaged,
      providerStages: this.providerStages,
      generationTrace: this.generationTrace,
    });
  }
}

const silentLog: WorkerStageLogger = {
  info() {},
  error() {},
};
