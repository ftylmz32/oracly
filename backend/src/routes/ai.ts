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
import type { ServerClock } from '../reading/clock.js';
import { systemClock } from '../reading/clock.js';
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
import { denySoulmateWithoutPremium } from '../reading/soulmate-ai-route-gate.js';
import type { SoulmateEntitlementGuard } from '../reading/soulmate-entitlement-guard.js';

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
          return reply.code(ritual.status).send(ritual.payload);
        }
        if (ritual.action === 'stored') {
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

        const run = async () => {
          const data = await service.handle(validated, modelHint, handleCtx);
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
