import type { FastifyInstance } from 'fastify';
import {
  fingerprintRequest,
  parseIdempotencyKey,
} from '../ai/request-fingerprint.js';
import { dreamReplayKey } from '../ai/dream-request-identity.js';
import { assertDreamInputSafe } from '../ai/dream-safety.js';
import type { AiProxyService } from '../ai/service.js';
import { asRecord } from '../ai/sanitize.js';
import { validateAiBody } from '../ai/validate-request.js';
import {
  createAppCheckVerifier,
  type AppCheckVerifier,
} from '../auth/app-check.js';
import { createAuthenticationService } from '../auth/create-auth.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, ProxyError, errorEnvelope, successEnvelope } from '../errors.js';
import { logSafe } from '../logging.js';
import { requireAppCheck } from '../middleware/app-check.js';
import { requireAuth } from '../middleware/auth.js';
import { createConcurrencyGate } from '../middleware/concurrency.js';
import { createDuplicateRequestGuard } from '../middleware/duplicate-request.js';
import { createExpensiveRateLimit } from '../middleware/expensive-rate.js';
import { createGlobalConcurrencyGate } from '../middleware/global-concurrency.js';
import { createGlobalRpmGate } from '../middleware/global-rpm.js';
import { createIdentityRateLimit } from '../middleware/rate-limit.js';
import { createResponseReplayRepository, type ResponseReplayRepository } from '../middleware/response-replay-repository.js';
import {
  narrativeDuplicateFingerprint,
  requireNarrativeAttemptInLockedEnv,
} from '../narrative-tarot-attempt.js';
import {
  requireYildiznameAttemptInLockedEnv,
  yildiznameDuplicateFingerprint,
} from '../narrative-yildizname-attempt.js';
import { createSharedWindowStore, type SharedWindowStore } from '../rate-limit/shared-window-store.js';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import { systemClock, toEpochMs, type ServerClock } from '../reading/clock.js';
import type { GemLedger } from '../reading/gem-ledger.js';
import {
  admitPaidTarot,
  failPaidTarot,
  finishPaidTarot,
  tarotBillingActive,
  type TarotHold,
} from '../reading/tarot-billing-gate.js';
import { isPaidTarot } from '../reading/tarot-billing-id.js';
import {
  admitFreeTextQuota,
  failFreeTextQuota,
  finishFreeTextQuota,
  type FreeTextHold,
} from '../reading/free-text-quota.js';
import {
  admitRitualQuota,
  type RitualHold,
} from '../reading/ritual-daily-quota.js';
import {
  failRitualQuota,
  finishRitualQuota,
} from '../reading/ritual-daily-quota-settle.js';
import type { ReadingOperationRepository } from '../reading/operation-repository.js';
import { claimedLegacyCoffee } from '../reading/reading-commerce-gate.js';
import { denySoulmateWithoutPremium } from '../reading/soulmate-ai-route-gate.js';
import type { SoulmateEntitlementGuard } from '../reading/soulmate-entitlement-guard.js';
import { admitLunaText, type LunaFreeHold } from '../reading/luna-premium-gate.js';
import { failLunaFree, finishLunaFree } from '../reading/luna-premium-settle.js';
import {
  authorizeSpeech,
  issueSpeechGrant,
  speechGrantIdFromBody,
  speechSignature,
} from '../reading/luna-speech-gate.js';
import { speechClipPath, speechStoreReady, writeSpeechClip } from '../reading/luna-speech-clip.js';
import { PREVIEW_DAY_MAX, previewRef } from '../reading/luna-speech-preview.js';
import {
  claimSpeech,
  claimSpeechDoc,
  finishSpeech,
  finishSpeechDoc,
  releaseSpeech,
  releaseSpeechDoc,
} from '../reading/luna-speech-settle.js';
import { releaseSpokenClaim } from '../reading/luna-speech-release.js';
import type { ReadingStagedObjectStore } from '../reading/staged-object-store.js';

export type AiRouteOptions = {
  appCheck?: AppCheckVerifier;
  sharedWindowStore?: SharedWindowStore;
  responseReplayRepository?: ResponseReplayRepository;
  gemLedger?: GemLedger;
  gemStore?: FirestoreLike;
  clock?: ServerClock;
  soulmateEntitlement?: SoulmateEntitlementGuard;
  freeTextQuotaStore?: FirestoreLike;
  ritualQuotaStore?: FirestoreLike;
  /** One free Luna text, then server premium. Separate from the day cap. */
  lunaAccessStore?: FirestoreLike;
  /** Speech of a delivered Luna or oracle reply. Preview phrases do not use it. */
  speechGrantStore?: FirestoreLike;
  /** Private clip bytes. The grant document keeps the path, never the audio. */
  speechObjectStore?: ReadingStagedObjectStore;
  /** Commerce on: the only coffee_analysis allowed fulfils a claimed pre-rollout operation. */
  readingOperations?: ReadingOperationRepository;
};

export async function registerAiRoutes(
  app: FastifyInstance,
  config: AppConfig,
  service: AiProxyService,
  options: AiRouteOptions = {},
): Promise<void> {
  const auth = requireAuth(createAuthenticationService(config));
  const gemLedger = options.gemLedger;
  const gemStore = options.gemStore;
  const clock = options.clock ?? systemClock();
  const appCheck = requireAppCheck(
    options.appCheck ?? createAppCheckVerifier(config),
  );
  const shared = options.sharedWindowStore ?? createSharedWindowStore(config);
  const rateLimit = createIdentityRateLimit(
    config.rateLimitMax,
    config.rateLimitWindowMs, shared,
  );
  const concurrency = createConcurrencyGate(config.maxConcurrent);
  const globalRpm = createGlobalRpmGate(config.globalAiRpm);
  const globalConcurrency = createGlobalConcurrencyGate(
    config.globalAiConcurrency,
  );
  const rejectDuplicate = createDuplicateRequestGuard(shared);
  const rejectExpensive = createExpensiveRateLimit(
    config.expensiveRateMax,
    config.rateLimitWindowMs, shared,
  );
  const replay = options.responseReplayRepository ?? createResponseReplayRepository(config);

  async function validateBodyPreHandler(
    request: import('fastify').FastifyRequest,
    reply: import('fastify').FastifyReply,
  ): Promise<void> {
    if (!isJson(request.headers['content-type'])) {
      await reply.code(200).send(errorEnvelope(ErrorCode.invalidRequest));
      return;
    }
    try {
      validateAiBody(request.body);
    } catch (error) {
      const proxy = error instanceof ProxyError ? error : null;
      const code = proxy?.code ?? ErrorCode.invalidRequest;
      const status = proxy?.httpStatus ?? 200;
      await reply.code(status).send(errorEnvelope(code));
    }
  }

  app.post(
    '/v1/ai/complete',
    {
      // validation → Auth → App Check → subject limits → global cost valves → handler
      preHandler: [
        validateBodyPreHandler,
        auth,
        appCheck,
        rateLimit,
        concurrency,
        globalRpm,
        globalConcurrency,
      ],
    },
    async (request, reply) => {
      const started = Date.now();
      const requestId = request.requestId;
      let tarotHold: TarotHold | null = null;
      let quotaHold: FreeTextHold | null = null;
      let ritualHold: RitualHold | null = null;
      let lunaHold: LunaFreeHold | null = null;
      let speechSpeak: {
        text: string;
        grantId: string;
        signature: string;
        preview?: boolean;
      } | null = null;
      let speechClaimed = false;
      let producerKey: string | null = null;
      let producerAttempt: string | null = null;
      try {
        const validated = validateAiBody(request.body);
        const fingerprint = fingerprintRequest(validated);
        const identity = request.identityKey ?? 'anon';
        const idemKey =
          parseIdempotencyKey(request.headers['idempotency-key']) ??
          (validated.operation === 'soulmate_draw' ? fingerprint : null);
        // Phase 6F.1 — Narrative V2 attempt is transport-only (never semantic).
        let duplicateFingerprint = fingerprint;
        if (
          validated.operation === 'tarot_reading' &&
          validated.mode === 'narrative_v2'
        ) {
          const narrativeAttempt = requireNarrativeAttemptInLockedEnv(
            config,
            idemKey,
          );
          if (narrativeAttempt != null) {
            duplicateFingerprint = narrativeDuplicateFingerprint(
              fingerprint,
              narrativeAttempt,
            );
          }
        }
        if (validated.operation === 'yildizname_reading') {
          const yildiznameAttempt = requireYildiznameAttemptInLockedEnv(
            config,
            idemKey,
          );
          if (yildiznameAttempt != null) {
            duplicateFingerprint = yildiznameDuplicateFingerprint(
              fingerprint,
              yildiznameAttempt,
            );
          }
        }
        // Dream Phase 3: safety wins over replay — checked before any claim,
        // cached body, duplicate gate or provider call.
        if (validated.operation === 'dream_analysis') {
          assertDreamInputSafe(validated.payload);
        }
        const soulmateDenied = await denySoulmateWithoutPremium({
          operation: validated.operation,
          identity,
          config,
          guard: options.soulmateEntitlement,
        });
        if (soulmateDenied) {
          return reply.code(soulmateDenied.status).send(soulmateDenied.body);
        }
        const luna = await admitLunaText({
          config,
          store: options.lunaAccessStore,
          guard: options.soulmateEntitlement,
          operation: validated.operation,
          oracleKind: validated.operation === 'oracle' ? validated.kind : null,
          identity,
          idempotencyKey: idemKey,
        });
        if (luna.action === 'reply') {
          return reply.code(luna.status).send(luna.payload);
        }
        lunaHold = luna.action === 'allow' ? luna.freeHold : null;
        const speech = await authorizeSpeech({
          config,
          store: options.speechGrantStore,
          guard: options.soulmateEntitlement,
          clock,
          operation: validated.operation,
          identity,
          text: validated.operation === 'tts' ? validated.text : '',
          grantId: speechGrantIdFromBody(request.body),
          signature: validated.operation === 'tts' ? speechSignature(validated) : '',
        });
        if (speech.action === 'reply') return reply.code(speech.status).send(speech.payload);
        if (speech.action === 'cached') {
          return reply.code(200).send(successEnvelope(speech.data));
        }
        speechSpeak = speech.action === 'speak' ? speech : null;
        const lunaStore = options.lunaAccessStore;
        const settleLuna = async (delivered: boolean) => {
          if (!lunaHold || !lunaStore) return;
          const hold = lunaHold;
          lunaHold = null;
          if (delivered) await finishLunaFree(lunaStore, identity, hold);
          else await failLunaFree(lunaStore, identity, hold);
        };
        const quota = await admitFreeTextQuota({
          config,
          store: options.freeTextQuotaStore,
          clock,
          operation: validated.operation,
          paidTarot: isPaidTarot(validated),
          identity,
          idempotencyKey: idemKey,
        });
        if (quota.action === 'reply') {
          await settleLuna(deliveredBody(quota.payload));
          return reply.code(quota.status).send(quota.payload);
        }
        quotaHold = quota.action === 'hold' ? quota.hold : null;
        const ritual = await admitRitualQuota({
          config,
          store: options.ritualQuotaStore,
          clock,
          operation: validated.operation,
          identity,
          idempotencyKey: idemKey,
        });
        if (ritual.action === 'reply') {
          await settleLuna(false);
          return reply.code(ritual.status).send(ritual.payload);
        }
        if (ritual.action === 'stored') {
          await settleLuna(deliveredBody(ritual.body));
          return reply.code(200).send(ritual.body);
        }
        ritualHold = ritual.action === 'hold' ? ritual.hold : null;
        const quotaStore = options.freeTextQuotaStore;
        const ritualStore = options.ritualQuotaStore;
        const releaseUnusedQuota = async () => {
          if (quotaHold && quotaStore) {
            const hold = quotaHold;
            quotaHold = null;
            await failFreeTextQuota(quotaStore, identity, hold);
          }
          if (ritualHold && ritualStore) {
            const hold = ritualHold;
            ritualHold = null;
            await failRitualQuota(ritualStore, identity, hold);
          }
          await settleLuna(false);
        };
        // Dream: a completed response replays only for the same semantic
        // request (language, narrative, symbols, emotions, memory).
        const billingOn = tarotBillingActive(config, gemLedger, gemStore);
        const replayKey =
          idemKey && validated.operation === 'dream_analysis'
            ? dreamReplayKey(idemKey, fingerprint)
            : idemKey;
        let replayAttempt: string | null = null;
        if (replayKey && !(billingOn && isPaidTarot(validated))) {
          const claim = await replay.claim(identity, replayKey);
          if (claim.kind === 'completed') {
            await settleLuna(true);
            if (quotaHold && quotaStore) {
              await finishFreeTextQuota(quotaStore, identity, quotaHold, claim.entry.body);
            }
            if (ritualHold && ritualStore) {
              await finishRitualQuota(ritualStore, identity, ritualHold, claim.entry.body);
            }
            reply.header('content-type', claim.entry.contentType);
            return reply.code(claim.entry.status).send(claim.entry.body);
          }
          if (claim.kind === 'in_progress') {
            await releaseUnusedQuota();
            return reply.code(409).send(errorEnvelope(ErrorCode.rateLimited));
          }
          replayAttempt = claim.attemptId;
          producerKey = replayKey;
          producerAttempt = claim.attemptId;
        }
        // Reading commerce: past the delivered replays, a coffee_analysis is
        // new work. It is allowed only for a claimed pre-rollout operation;
        // the catch below releases the free slot and the replay claim.
        if (
          validated.operation === 'coffee_analysis' &&
          config.readingCommerceEnabled &&
          !(await claimedLegacyCoffee(options.readingOperations, identity, validated.payload))
        ) {
          throw new ProxyError(ErrorCode.readingEntitlementRequired, 403);
        }
        if (
          !(billingOn && isPaidTarot(validated)) &&
          await rejectDuplicate(request, reply, validated.operation, duplicateFingerprint)
        ) {
          await releaseUnusedQuota();
          return;
        }
        if (await rejectExpensive(request, reply, validated.operation)) {
          await releaseUnusedQuota();
          return;
        }
        const admission = await admitPaidTarot({
          config,
          ledger: gemLedger,
          store: gemStore,
          clock,
          validated,
          identity,
          idemKey,
          fingerprint,
        });
        if (admission.action === 'reply') {
          await releaseUnusedQuota();
          return reply.code(admission.status).send(admission.payload);
        }
        tarotHold = admission.action === 'hold' ? admission.hold : null;
        const modelHint = asRecord(request.body)?.model;
        const payload = asRecord(asRecord(request.body)?.payload);
        const imagePayloadPresent =
          typeof payload?.imageBase64 === 'string' &&
          (payload.imageBase64 as string).length > 64;
        const bridgeKey =
          (payload?.readingPhase === 'observe' || payload?.readingPhase === 'write') &&
          typeof payload.readingBridgeKey === 'string'
            ? parseIdempotencyKey(payload.readingBridgeKey)
            : null;
        const handleCtx = {
          identity,
          parentKey:
            bridgeKey ??
            idemKey ??
            `${validated.operation}:${fingerprint.slice(0, 48)}`,
        };

        const spoken =
          speechSpeak && validated.operation === 'tts'
            ? { ...validated, text: speechSpeak.text }
            : validated;
        if (speechSpeak && options.speechGrantStore) {
          const speechStore = options.speechGrantStore;
          const spokenTurn = speechSpeak;
          const claimed = spokenTurn.preview
            ? await claimSpeechDoc(
                speechStore,
                previewRef(speechStore, spokenTurn.grantId),
                identity,
                spokenTurn.signature,
                toEpochMs(clock.now()),
                options.speechObjectStore,
                PREVIEW_DAY_MAX,
              )
            : await claimSpeech(
                speechStore,
                spokenTurn.grantId,
                identity,
                spokenTurn.signature,
                toEpochMs(clock.now()),
                options.speechObjectStore,
              );
          if (claimed === 'busy' || claimed === 'capped') {
            await releaseUnusedQuota();
            return reply.code(409).send(errorEnvelope(ErrorCode.rateLimited));
          }
          if (claimed === 'unavailable') {
            await releaseUnusedQuota();
            return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
          }
          if (claimed !== 'go') {
            return reply.code(200).send(successEnvelope(claimed));
          }
          speechClaimed = true;
          const objects = options.speechObjectStore;
          const ready = objects ? await speechStoreReady(objects, identity) : false;
          if (!ready) {
            await releaseSpokenClaim(speechStore, identity, spokenTurn);
            speechClaimed = false;
            await releaseUnusedQuota();
            return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
          }
        }
        const run = async () => {
          const data = await service.handle(spoken, modelHint, handleCtx);
          return { status: 200, body: successEnvelope(data) };
        };

        const result = await run();
        if (quotaHold && quotaStore) {
          await finishFreeTextQuota(quotaStore, identity, quotaHold, result.body);
          quotaHold = null;
        }
        if (ritualHold && ritualStore) {
          await finishRitualQuota(ritualStore, identity, ritualHold, result.body);
          ritualHold = null;
        }
        await settleLuna(true);
        const speechStore = options.speechGrantStore;
        if (speechClaimed && speechSpeak && speechStore) {
          const clip = asRecord(asRecord(result.body)?.data);
          const audio = clip?.audioBase64;
          const spokenTurn = speechSpeak;
          if (typeof audio === 'string' && audio.length >= 32) {
            const objects = options.speechObjectStore;
            const clipPath = speechClipPath(identity, spokenTurn.grantId, spokenTurn.signature);
            try {
              if (!objects) throw new Error('speech_store_missing');
              await writeSpeechClip(objects, clipPath, audio);
            } catch {
              await releaseSpokenClaim(speechStore, identity, spokenTurn);
              speechClaimed = false;
              await releaseUnusedQuota();
              return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
            }
            if (spokenTurn.preview) {
              await finishSpeechDoc(
                speechStore,
                previewRef(speechStore, spokenTurn.grantId),
                identity,
                spokenTurn.signature,
                clipPath,
              );
            } else {
              await finishSpeech(
                speechStore,
                spokenTurn.grantId,
                identity,
                spokenTurn.signature,
                clipPath,
              );
            }
          } else if (spokenTurn.preview) {
            await releaseSpeechDoc(
              speechStore,
              previewRef(speechStore, spokenTurn.grantId),
              identity,
              spokenTurn.signature,
            );
          } else {
            await releaseSpeech(speechStore, spokenTurn.grantId, identity, spokenTurn.signature);
          }
          speechClaimed = false;
        }
        if (
          speechStore &&
          (validated.operation === 'chat' || validated.operation === 'oracle')
        ) {
          const data = asRecord(asRecord(result.body)?.data);
          const text = data?.text;
          if (data && typeof text === 'string' && text.trim()) {
            data.speechGrant = await issueSpeechGrant({
              store: speechStore,
              clock,
              identity,
              kind: validated.operation === 'oracle' ? 'oracle' : 'luna',
              text,
            });
          }
        }
        if (tarotHold && gemStore) {
          const done = await finishPaidTarot(gemStore, clock, gemLedger ?? null, tarotHold, result.body);
          tarotHold = null;
          if (!done.deliver) return reply.code(done.status).send(done.payload);
        }
        if (replayKey && replayAttempt) await replay.complete(identity, replayKey, replayAttempt, {
          status: result.status, body: result.body, contentType: 'application/json',
        });

        logSafe(request.log, 'info', 'ai_complete', {
          requestId,
          operation: validated.operation,
          model: config.openaiModel,
          latencyMs: Date.now() - started,
          status: result.status,
          imagePayloadPresent:
            validated.operation === 'coffee_analysis' ||
            validated.operation === 'palm_analysis'
              ? imagePayloadPresent
              : undefined,
          providerResponsePresent: true,
          parsedOk: true,
        });
        return reply.code(result.status).send(result.body);
      } catch (error) {
        if (quotaHold && options.freeTextQuotaStore) {
          const hold = quotaHold;
          quotaHold = null;
          try {
            await failFreeTextQuota(
              options.freeTextQuotaStore,
              request.identityKey ?? 'anon',
              hold,
            );
          } catch {
            // The reservation stays open. The same operation id resumes it.
          }
        }
        if (ritualHold && options.ritualQuotaStore && request.raw.aborted !== true) {
          const hold = ritualHold;
          ritualHold = null;
          try {
            await failRitualQuota(
              options.ritualQuotaStore,
              request.identityKey ?? 'anon',
              hold,
            );
          } catch {
            // The reservation stays open. The same operation id resumes it.
          }
        }
        if (speechClaimed && speechSpeak && options.speechGrantStore && request.raw.aborted !== true) {
          const spoken = speechSpeak;
          const speechStore = options.speechGrantStore;
          speechClaimed = false;
          try {
            if (spoken.preview) {
              await releaseSpeechDoc(
                speechStore,
                previewRef(speechStore, spoken.grantId),
                request.identityKey ?? 'anon',
                spoken.signature,
              );
            } else {
              await releaseSpeech(
                speechStore,
                spoken.grantId,
                request.identityKey ?? 'anon',
                spoken.signature,
              );
            }
          } catch {
            // The claim expires. The same grant can speak after that.
          }
        }
        if (lunaHold && options.lunaAccessStore && request.raw.aborted !== true) {
          const hold = lunaHold;
          lunaHold = null;
          try {
            await failLunaFree(options.lunaAccessStore, request.identityKey ?? 'anon', hold);
          } catch {
            // The free turn stays open for this same operation id.
          }
        }
        if (producerKey && producerAttempt) {
          try {
            await replay.abandon(request.identityKey ?? 'anon', producerKey, producerAttempt);
          } catch {
            // The claim expires on its own. The same key can resume after that.
          }
        }
        if (tarotHold && gemStore) {
          const hold = tarotHold;
          tarotHold = null;
          try {
            await failPaidTarot(gemStore, clock, hold, gemLedger ?? null);
          } catch {
            // The hold stays open. The same operation id resumes it.
          }
        }
        const proxy = error instanceof ProxyError ? error : null;
        const code = proxy?.code ?? ErrorCode.internalError;
        const status = proxy?.httpStatus ?? 200;
        const payload = asRecord(asRecord(request.body)?.payload);
        const imagePayloadPresent =
          typeof payload?.imageBase64 === 'string' &&
          (payload.imageBase64 as string).length > 64;
        const diagnostic = diagnosticCodes(proxy?.details);
        logSafe(request.log, 'warn', 'ai_complete_failed', {
          requestId,
          operation:
            typeof asRecord(request.body)?.operation === 'string'
              ? String(asRecord(request.body)?.operation)
              : undefined,
          latencyMs: Date.now() - started,
          status,
          errorCode: code,
          imagePayloadPresent,
          providerResponsePresent:
            code !== ErrorCode.invalidRequest && code !== ErrorCode.dreamSafetyBlocked,
          parsedOk: false,
          bindFailure: diagnostic.bindFailure,
          priorViolation: diagnostic.priorViolation,
          diagnosticStage: diagnostic.diagnosticStage,
        });
        return reply.code(status).send(errorEnvelope(code, proxy?.details));
      }
    },
  );
}

function deliveredBody(payload: unknown): boolean {
  return !!payload && typeof payload === 'object' && (payload as { success?: unknown }).success === true;
}

function diagnosticCodes(details: Record<string, unknown> | undefined): {
  bindFailure?: string;
  priorViolation?: string;
  diagnosticStage?: string;
} {
  return {
    bindFailure: codeField(details, 'bindFailure'),
    priorViolation: codeField(details, 'priorViolation'),
    diagnosticStage: codeField(details, 'stage'),
  };
}

function codeField(
  details: Record<string, unknown> | undefined,
  key: string,
): string | undefined {
  const value = details?.[key];
  if (typeof value !== 'string' || !/^[a-z_]{3,40}$/.test(value)) return undefined;
  return value;
}

function isJson(contentType: unknown): boolean {
  if (typeof contentType !== 'string') return false;
  return contentType.toLowerCase().includes('application/json');
}
