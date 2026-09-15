/**
 * BATCH 5F — completes the existing ReadingOperation/ReadingFlow/GemLedger
 * wiring for the real server entrypoint.
 *
 * Before this file, `backend/src/index.ts` called `buildServer({ config })`
 * without `readingFlow` or `gemLedger`. `registerReadingOperationRoutes`
 * already falls back to real defaults when those options are absent, but
 * `registerReadingFlowRoutes` and `registerGemAccelerationRoutes` do not —
 * every claim/complete/fail/active/acceleration route unconditionally
 * returned 503 in production. This is not a new system: it constructs the
 * same already-tested classes (`ReadingOperationService`, `GemLedger`,
 * `ReadingFlow`) the exact way `backend/tests/reading-flow.test.ts` does,
 * just wired to the real Firestore client instead of a test fake.
 */
import { Firestore } from '@google-cloud/firestore';
import type { AppConfig } from '../config.js';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import { systemClock, type ServerClock } from './clock.js';
import { provisionalGemCostPolicy } from './gem-cost-policy.js';
import { GemLedger } from './gem-ledger.js';
import {
  createReadingOperationInputRepository,
  type ReadingOperationInputRepository,
} from './operation-input-repository.js';
import { ReadingOperationInputService } from './operation-input-service.js';
import {
  FailClosedSoulmatePortraitStore,
  GcsSoulmatePortraitStore,
  type SoulmatePortraitStore,
} from './soulmate-portrait-store.js';
import {
  createSoulmateEntitlementGuard,
  type SoulmateEntitlementGuard,
} from './soulmate-entitlement-guard.js';
import {
  createReadingOperationRepository,
  type ReadingOperationRepository,
} from './operation-repository.js';
import { ReadingOperationService } from './operation-service.js';
import {
  createReadingStagedImageRepository,
  type ReadingStagedImageRepository,
} from './operation-staged-image-repository.js';
import { ReadingStagedImageService } from './operation-staged-image-service.js';
import { ReadingFlow } from './reading-flow.js';
import { ReadingResultRepository } from './reading-result-repository.js';
import { createReadingTaskScheduler, type ReadingTaskScheduler } from './reading-task-scheduler.js';
import {
  FirebaseReadingCompletionNotifier,
  ReadingNotificationTokens,
} from './reading-notifications.js';
import type { ReadingCompletionNotifier } from './reading-processor.js';
import { FirestoreProviderStageRepository, type ProviderStageRepository } from './provider-stage-repository.js';
import {
  createReadingStagedObjectStore,
  type ReadingStagedObjectStore,
} from './staged-object-store.js';
import {
  provisionalWaitPolicy,
  SOULMATE_NO_COMMERCIAL_WAIT_MS,
  type WaitPolicy,
} from './wait-policy.js';

export type ProductionReadingWiring = {
  clock: ServerClock;
  policy: WaitPolicy;
  repository: ReadingOperationRepository;
  operations: ReadingOperationService;
  gemLedger: GemLedger | null;
  readingFlow: ReadingFlow | null;
  inputRepository: ReadingOperationInputRepository;
  stagedImageRepository: ReadingStagedImageRepository;
  stagedObjectStore: ReadingStagedObjectStore;
  stagedImages: ReadingStagedImageService;
  results: ReadingResultRepository | null;
  scheduler: ReadingTaskScheduler;
  notificationTokens: ReadingNotificationTokens | null;
  notifier: ReadingCompletionNotifier;
  providerStages: ProviderStageRepository | null;
  soulmateInputs: ReadingOperationInputService;
  soulmatePortraits: SoulmatePortraitStore;
  soulmateEntitlement: SoulmateEntitlementGuard;
};

let sharedFirestore: Firestore | null = null;

/** Fails closed (null) exactly like createReadingOperationRepository — never
 * an in-process fake pretending to be durable. */
function firestoreClient(config: AppConfig): FirestoreLike | null {
  if (!config.firebaseProjectId || !config.entitlementDurableRequired) {
    return null;
  }
  try {
    sharedFirestore ??= new Firestore({
      projectId: config.firebaseProjectId,
      databaseId: config.firestoreDatabaseId,
    });
    return sharedFirestore;
  } catch {
    return null;
  }
}

/**
 * Builds the same real objects the reading-flow/gem-acceleration routes
 * need, for the production entrypoint to pass into buildServer(). Returns
 * null pieces (never a fake) when Firestore truly is not configured —
 * routes then keep their existing fail-closed 503 behavior, unchanged.
 */
export function createProductionReadingWiring(
  config: AppConfig,
): ProductionReadingWiring {
  const clock = systemClock();
  // BATCH 5G: Soulmate has no commercial wait in the live product today —
  // see SOULMATE_NO_COMMERCIAL_WAIT_MS. Coffee/Palm keep their real
  // provisional durations untouched.
  //
  // `config.readingWaitOverrideMs` is a development-only escape hatch
  // (hard-locked to null in production/staging by config.ts itself, same
  // rule as devAuthBypass/appCheckBypass) for live end-to-end testing of
  // the create -> stage -> wait -> resume/claim -> execute pipeline
  // without a real multi-hour wait. It never touches Soulmate's own
  // already-near-zero wait, and it is not a commercial value change.
  const waitOverride = config.readingWaitOverrideMs;
  const policy = provisionalWaitPolicy({
    soulmate: SOULMATE_NO_COMMERCIAL_WAIT_MS,
    ...(waitOverride != null
      ? { coffee: waitOverride, palm: waitOverride }
      : {}),
  });
  const repository = createReadingOperationRepository(config);
  const operations = new ReadingOperationService(repository, clock, policy);
  const inputRepository = createReadingOperationInputRepository(config);
  const stagedImageRepository = createReadingStagedImageRepository(config);
  const stagedObjectStore = createReadingStagedObjectStore(config);
  const stagedImages = new ReadingStagedImageService(
    stagedImageRepository,
    stagedObjectStore,
    operations,
    clock,
    config,
    (event) => console.error(JSON.stringify(event)),
  );
  const firestore = firestoreClient(config);
  const gemLedger = firestore
    ? new GemLedger(firestore, clock, provisionalGemCostPolicy())
    : null;
  const readingFlow = firestore
    ? new ReadingFlow(firestore, clock, operations, gemLedger)
    : null;
  const results = firestore ? new ReadingResultRepository(firestore) : null;
  const providerStages = firestore ? new FirestoreProviderStageRepository(firestore) : null;
  const scheduler = createReadingTaskScheduler(config);
  const notificationTokens = firestore ? new ReadingNotificationTokens(firestore) : null;
  const notifier = notificationTokens
    ? new FirebaseReadingCompletionNotifier(config, notificationTokens)
    : { async notifyCompleted() {} };
  const soulmateInputs = new ReadingOperationInputService(inputRepository, operations, clock);
  // SMD1 — same bucket Coffee/Palm staged images already use
  // (`config.readingStagingBucket`), a distinct object-path prefix. No
  // new bucket, no infra change.
  const soulmatePortraits: SoulmatePortraitStore = firestore
    ? new GcsSoulmatePortraitStore(stagedObjectStore, firestore)
    : new FailClosedSoulmatePortraitStore();
  const soulmateEntitlement = createSoulmateEntitlementGuard(
    config,
    () => new Firestore({ projectId: config.firebaseProjectId!, databaseId: config.firestoreDatabaseId }),
  );
  return {
    clock,
    policy,
    repository,
    operations,
    gemLedger,
    readingFlow,
    inputRepository,
    stagedImageRepository,
    stagedObjectStore,
    stagedImages,
    results,
    scheduler,
    notificationTokens,
    notifier,
    providerStages,
    soulmateInputs,
    soulmatePortraits,
    soulmateEntitlement,
  };
}
