import Fastify from 'fastify';
import helmet from '@fastify/helmet';
import './types.js';
import { AiProxyService } from './ai/service.js';
import type { AppCheckVerifier } from './auth/app-check.js';
import { createAppCheckVerifier } from './auth/app-check.js';
import type { AppConfig } from './config.js';
import { ErrorCode, ProxyError, errorEnvelope } from './errors.js';
import { createRequestId, logSafe } from './logging.js';
import { registerAiRoutes } from './routes/ai.js';
import { registerReadingOperationRoutes } from './routes/reading-operations.js';
import { registerGemAccelerationRoutes } from './routes/gem-acceleration.js';
import { registerRewardedAdRoutes, type RewardedAdRouteOptions } from './routes/rewarded-ads.js';
import { registerReadingFlowRoutes } from './routes/reading-flow-routes.js';
import { registerReadingOperationInputRoutes } from './routes/reading-operation-input-routes.js';
import { registerReadingStagedImageRoutes } from './routes/reading-staged-image-routes.js';
import { registerHealth } from './routes/health.js';
import { registerBillingRoutes } from './routes/billing.js';
import { registerReviewAccessRoutes } from './routes/review-access.js';
import type { BillingProviders } from './billing/types.js';
import type { EntitlementBindingRepository } from './billing/entitlement-repository.js';
import {
  createReadingOperationRepository,
  type ReadingOperationRepository,
} from './reading/operation-repository.js';
import type { ReadingOperationInputRepository } from './reading/operation-input-repository.js';
import {
  createReadingStagedImageRepository,
  type ReadingStagedImageRepository,
} from './reading/operation-staged-image-repository.js';
import { ReadingOperationService } from './reading/operation-service.js';
import { ReadingStagedImageService } from './reading/operation-staged-image-service.js';
import {
  createReadingStagedObjectStore,
  type ReadingStagedObjectStore,
} from './reading/staged-object-store.js';
import { systemClock, type ServerClock } from './reading/clock.js';
import { provisionalWaitPolicy, type WaitPolicy } from './reading/wait-policy.js';
import type { GemLedger } from './reading/gem-ledger.js';
import type { ReadingFlow } from './reading/reading-flow.js';
import type { OpenAiFetch } from './types.js';
import type { ReadingTaskScheduler } from './reading/reading-task-scheduler.js';
import type { ReadingResultRepository } from './reading/reading-result-repository.js';
import type { ReadingProcessor } from './reading/reading-processor.js';
import type { SoulmatePortraitStore } from './reading/soulmate-portrait-store.js';
import { registerReadingWorkerRoutes } from './routes/reading-worker-routes.js';
import { registerReadingNotificationRoutes } from './routes/reading-notification-routes.js';
import type { ReadingNotificationTokens } from './reading/reading-notifications.js';
import { registerAccountDeletionRoute } from './routes/account-deletion.js';
import type { AccountDeletionRepository } from './account/account-deletion.js';
import type { SharedWindowStore } from './rate-limit/shared-window-store.js';
import type { ResponseReplayRepository } from './middleware/response-replay-repository.js';

export type BuildOptions = {
  config: AppConfig;
  fetchImpl?: OpenAiFetch;
  logger?: boolean;
  /** Override App Check verifier (tests). */
  appCheck?: AppCheckVerifier;
  /** Override billing store verifiers (tests). */
  billing?: BillingProviders;
  /** Override the durable entitlement-binding store (tests). */
  entitlementRepository?: EntitlementBindingRepository;
  /** Override the durable reading-operation store (tests). */
  readingOperationRepository?: ReadingOperationRepository;
  /** Durable store for a reading operation's structured input (Soulmate). */
  readingOperationInputRepository?: ReadingOperationInputRepository;
  readingClock?: ServerClock;
  readingWaitPolicy?: WaitPolicy;
  /** Durable gem ledger. Required for acceleration. */
  gemLedger?: GemLedger;
  rewardedAds?: Omit<RewardedAdRouteOptions, 'ledger' | 'appCheck' | 'clock'>;
  readingFlow?: ReadingFlow;
  /** Durable Coffee/Palm staged-image metadata store (BATCH 5I). */
  readingStagedImageRepository?: ReadingStagedImageRepository;
  /** Private GCS object store for staged Coffee/Palm images (BATCH 5I). */
  readingStagedObjectStore?: ReadingStagedObjectStore;
  /**
   * Shared staged-image service — used by both the staging route and the
   * AI proxy's retrieval-for-processing path. Built from the two options
   * above when absent (tests may also override this directly).
   */
  readingStagedImages?: ReadingStagedImageService;
  readingTaskScheduler?: ReadingTaskScheduler;
  readingResults?: ReadingResultRepository;
  readingProcessor?: ReadingProcessor;
  /** SMD1 — private authenticated Soulmate portrait storage. */
  readingSoulmatePortraits?: SoulmatePortraitStore;
  readingNotificationTokens?: ReadingNotificationTokens;
  accountDeletionRepository?: AccountDeletionRepository;
  sharedWindowStore?: SharedWindowStore;
  responseReplayRepository?: ResponseReplayRepository;
};

export async function buildServer(options: BuildOptions) {
  const { config } = options;
  const appCheck = options.appCheck ?? createAppCheckVerifier(config);
  const app = Fastify({
    logger: options.logger
      ? {
          level: 'info',
          redact: {
            paths: [
              'req.headers.authorization',
              'req.headers.Authorization',
              'req.headers.cookie',
              'req.headers["x-firebase-appcheck"]',
              'req.headers["X-Firebase-AppCheck"]',
              '*.accessToken',
              '*.refreshToken',
              '*.openaiApiKey',
              '*.purchaseToken',
              'req.body.purchaseToken',
            ],
            censor: '[redacted]',
          },
        }
      : false,
    bodyLimit: config.maxBodyBytes,
    // Must cover Soulmate GPT Image latency (~120s app + buffer). Cloud Run
    // request timeout should be >= this value (deploy script uses 180s).
    requestTimeout:
      Math.max(config.openaiTimeoutMs, config.openaiImageTimeoutMs) + 15_000,
    genReqId: createRequestId,
  });

  app.decorateRequest('requestId', '');
  app.decorateRequest('identityKey', '');
  app.decorateRequest('authSubject', '');

  app.addHook('onRequest', async (request, reply) => {
    request.requestId = String(request.id);
    reply.header('x-request-id', request.requestId);
    reply.header('x-content-type-options', 'nosniff');
    reply.header('cache-control', 'no-store');
  });

  await app.register(helmet, {
    global: true,
    contentSecurityPolicy: false,
    crossOriginEmbedderPolicy: false,
  });

  app.setErrorHandler((error, request, reply) => {
    // Cloud Tasks treats any 2xx as success and will delete the task.
    // Client/parse failures must be 4xx; unknown failures must be 5xx.
    if (error instanceof ProxyError) {
      const status = error.httpStatus >= 400 ? error.httpStatus : 500;
      return reply.code(status).send(errorEnvelope(error.code));
    }
    const code = (error as { code?: string }).code;
    const status = (error as { statusCode?: number }).statusCode;
    if (code === 'FST_ERR_CTP_BODY_TOO_LARGE' || status === 413) {
      return reply.code(413).send(errorEnvelope(ErrorCode.invalidRequest));
    }
    if (
      code === 'FST_ERR_CTP_INVALID_MEDIA_TYPE' ||
      code === 'FST_ERR_CTP_EMPTY_JSON_BODY' ||
      code === 'FST_ERR_CTP_INVALID_JSON_BODY' ||
      status === 400 ||
      status === 415
    ) {
      return reply.code(status === 415 ? 415 : 400).send(errorEnvelope(ErrorCode.invalidRequest));
    }
    if (typeof status === 'number' && status >= 400 && status < 500) {
      return reply.code(status).send(errorEnvelope(ErrorCode.invalidRequest));
    }
    logSafe(request.log, 'error', 'unhandled_error', {
      requestId: request.requestId || String(request.id),
      status: 500,
      errorCode: ErrorCode.internalError,
    });
    return reply.code(500).send(errorEnvelope(ErrorCode.internalError));
  });

  await registerHealth(app, config, appCheck);
  await registerBillingRoutes(
    app,
    config,
    options.billing ?? {},
    options.entitlementRepository,
    options.sharedWindowStore,
  );
  await registerAccountDeletionRoute(app, config, {
    repository: options.accountDeletionRepository,
    appCheck,
  });
  await registerReviewAccessRoutes(app, config);
  const readingClock = options.readingClock ?? systemClock();
  const readingWaitPolicy = options.readingWaitPolicy ?? provisionalWaitPolicy();
  const readingOperationRepository =
    options.readingOperationRepository ?? createReadingOperationRepository(config);
  // Shared by the staging route and the AI proxy's retrieval-for-processing
  // path so both see the same durable state (matters most for tests using
  // in-memory fakes).
  const stagedImages =
    options.readingStagedImages ??
    new ReadingStagedImageService(
      options.readingStagedImageRepository ?? createReadingStagedImageRepository(config),
      options.readingStagedObjectStore ?? createReadingStagedObjectStore(config),
      new ReadingOperationService(readingOperationRepository, readingClock, readingWaitPolicy),
      readingClock,
      config,
    );
  const service = new AiProxyService(config, options.fetchImpl, stagedImages);
  await registerAiRoutes(app, config, service, {
    appCheck,
    sharedWindowStore: options.sharedWindowStore,
    responseReplayRepository: options.responseReplayRepository,
  });
  await registerReadingOperationRoutes(app, config, {
    appCheck,
    repository: readingOperationRepository,
    clock: readingClock,
    policy: readingWaitPolicy,
    // Was missing entirely: without this, `POST /v1/reading-operations`
    // never calls `flow.remember()`, so the `readingOperationActive`
    // pointer this same flow's own `/v1/reading-flow/active` route reads
    // back (registerReadingFlowRoutes below, which DOES receive `flow`)
    // is never written — every operation is created successfully but is
    // permanently invisible to recovery. Confirmed live: a real device
    // app-restart mid-`waiting` never found its own just-created,
    // just-staged operation because of this, in every environment,
    // regardless of the client-side resume fix.
    flow: options.readingFlow,
  });
  await registerGemAccelerationRoutes(app, config, {
    appCheck,
    ledger: options.gemLedger,
    clock: readingClock,
    scheduler: options.readingTaskScheduler,
    operationRepository: readingOperationRepository,
    stagedImageRepository: options.readingStagedImageRepository,
  });
  await registerRewardedAdRoutes(app, config, { appCheck, ledger: options.gemLedger, clock: readingClock, ...options.rewardedAds });
  await registerReadingFlowRoutes(app, config, {
    appCheck,
    flow: options.readingFlow,
    clock: readingClock,
    stagedImages,
  });
  await registerReadingOperationInputRoutes(app, config, {
    appCheck,
    inputRepository: options.readingOperationInputRepository,
    operationRepository: readingOperationRepository,
    clock: readingClock,
    policy: readingWaitPolicy,
    scheduler: options.readingTaskScheduler,
  });
  await registerReadingStagedImageRoutes(app, config, {
    appCheck,
    stagedImages,
    clock: readingClock,
    policy: readingWaitPolicy,
    scheduler: options.readingTaskScheduler,
  });
  await registerReadingWorkerRoutes(app, config, {
    appCheck,
    processor: options.readingProcessor,
    results: options.readingResults,
    soulmatePortraits: options.readingSoulmatePortraits,
  });
  await registerReadingNotificationRoutes(app, config, {
    appCheck,
    tokens: options.readingNotificationTokens,
  });
  return app;
}
