import { loadConfig } from './config.js';
import { loadEnvFile } from './load-env.js';
import { createProductionReadingWiring } from './reading/production-wiring.js';
import { buildServer } from './server.js';
import { AiProxyService } from './ai/service.js';
import { ReadingProcessor } from './reading/reading-processor.js';

loadEnvFile();
const config = loadConfig();
const readingWiring = createProductionReadingWiring(config);
const processorService = new AiProxyService(config, undefined, readingWiring.stagedImages);
const readingProcessor =
  readingWiring.readingFlow && readingWiring.results
    ? new ReadingProcessor(
        readingWiring.repository,
        readingWiring.readingFlow,
        readingWiring.stagedImageRepository,
        readingWiring.stagedImages,
        readingWiring.results,
        processorService,
        readingWiring.clock,
        readingWiring.notifier,
        config.readingWorkerStopAfterStaged,
        readingWiring.providerStages ?? undefined,
        {
          pipelineVersion: 'reading-pipeline-r5',
          interpretationContractVersion: 'coffee-palm-contract-v2',
          promptRulesVersion: 'reading-prompts-r4',
          modelIdentifier: config.openaiModel,
        },
        readingWiring.soulmateInputs,
        readingWiring.soulmatePortraits,
        readingWiring.soulmateEntitlement,
        config.openaiImageModel,
      )
    : undefined;
const app = await buildServer({
  config,
  logger: true,
  readingOperationRepository: readingWiring.repository,
  readingClock: readingWiring.clock,
  readingWaitPolicy: readingWiring.policy,
  gemLedger: readingWiring.gemLedger ?? undefined,
  readingFlow: readingWiring.readingFlow ?? undefined,
  readingOperationInputRepository: readingWiring.inputRepository,
  readingStagedImageRepository: readingWiring.stagedImageRepository,
  readingStagedObjectStore: readingWiring.stagedObjectStore,
  readingStagedImages: readingWiring.stagedImages,
  readingTaskScheduler: readingWiring.scheduler,
  readingResults: readingWiring.results ?? undefined,
  readingProcessor,
  readingNotificationTokens: readingWiring.notificationTokens ?? undefined,
  readingSoulmatePortraits: readingWiring.soulmatePortraits,
});

async function shutdown(signal: string): Promise<void> {
  app.log.info({ signal }, 'oracly-ai-proxy shutting down');
  try {
    await app.close();
  } catch (error) {
    app.log.error(error);
  }
  process.exit(0);
}

process.on('SIGTERM', () => {
  void shutdown('SIGTERM');
});
process.on('SIGINT', () => {
  void shutdown('SIGINT');
});

try {
  await app.listen({ host: config.host, port: config.port });
  const locked = config.appEnv === 'production' || config.appEnv === 'staging';
  const trafficReady =
    Boolean(config.openaiApiKey) &&
    (config.authMode === 'jwks' || config.authMode === 'hs256');
  app.log.info(
    {
      env: config.appEnv,
      host: config.host,
      port: config.port,
      authRequired: config.authRequired,
      authMode: config.authMode,
      vision: config.openaiVision,
      model: config.openaiModel,
      openaiConfigured: Boolean(config.openaiApiKey),
      trafficReady: locked ? trafficReady : undefined,
    },
    'oracly-ai-proxy listening',
  );
  if (locked && !trafficReady) {
    app.log.warn(
      {
        authMode: config.authMode,
        openaiConfigured: Boolean(config.openaiApiKey),
      },
      'oracly-ai-proxy not ready — set OPENAI_API_KEY and FIREBASE_PROJECT_ID (or JWKS)',
    );
  }
  if (locked && !config.openaiVision) {
    app.log.warn(
      { vision: false },
      'oracly-ai-proxy vision disabled — coffee_analysis and palm_analysis return image_analysis_unavailable',
    );
  }
  if (locked && !readingWiring.readingFlow) {
    app.log.warn(
      { firestoreConfigured: Boolean(config.firebaseProjectId) },
      'oracly-ai-proxy reading-flow unavailable — claim/complete/fail/active and gem acceleration return 503',
    );
  }
  if (locked && !config.readingStagingBucket) {
    app.log.warn(
      {},
      'oracly-ai-proxy READING_STAGING_BUCKET unset — Coffee/Palm staged-image upload and operation-based retrieval fail closed (no_configuration)',
    );
  }
} catch (error) {
  app.log.error(error);
  process.exit(1);
}
