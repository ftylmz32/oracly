import type { FastifyInstance } from 'fastify';
import {
  fingerprintRequest,
  parseIdempotencyKey,
} from '../ai/request-fingerprint.js';
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
import { createIdempotencyStore } from '../middleware/idempotency.js';
import { createIdentityRateLimit } from '../middleware/rate-limit.js';

export type AiRouteOptions = {
  appCheck?: AppCheckVerifier;
};

export async function registerAiRoutes(
  app: FastifyInstance,
  config: AppConfig,
  service: AiProxyService,
  options: AiRouteOptions = {},
): Promise<void> {
  const auth = requireAuth(createAuthenticationService(config));
  const appCheck = requireAppCheck(
    options.appCheck ?? createAppCheckVerifier(config),
  );
  const rateLimit = createIdentityRateLimit(
    config.rateLimitMax,
    config.rateLimitWindowMs,
  );
  const concurrency = createConcurrencyGate(config.maxConcurrent);
  const globalRpm = createGlobalRpmGate(config.globalAiRpm);
  const globalConcurrency = createGlobalConcurrencyGate(
    config.globalAiConcurrency,
  );
  const rejectDuplicate = createDuplicateRequestGuard();
  const rejectExpensive = createExpensiveRateLimit(
    config.expensiveRateMax,
    config.rateLimitWindowMs,
  );
  const idempotency = createIdempotencyStore();

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
      try {
        const validated = validateAiBody(request.body);
        const fingerprint = fingerprintRequest(validated);
        const identity = request.identityKey ?? 'anon';
        const idemKey =
          parseIdempotencyKey(request.headers['idempotency-key']) ??
          (validated.operation === 'soulmate_draw' ? fingerprint : null);
        if (idemKey) {
          const cached = idempotency.lookup(identity, idemKey);
          if (cached) {
            return idempotency.replyCached(reply, cached);
          }
        }
        if (rejectDuplicate(request, reply, validated.operation, fingerprint)) {
          return;
        }
        if (rejectExpensive(request, reply, validated.operation)) {
          return;
        }
        const modelHint = asRecord(request.body)?.model;
        const payload = asRecord(asRecord(request.body)?.payload);
        const imagePayloadPresent =
          typeof payload?.imageBase64 === 'string' &&
          (payload.imageBase64 as string).length > 64;

        const run = async () => {
          const data = await service.handle(validated, modelHint);
          return { status: 200, body: successEnvelope(data) };
        };

        const result = idemKey
          ? await idempotency.run(identity, idemKey, run)
          : {
              at: Date.now(),
              ...(await run()),
            };

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
        const proxy = error instanceof ProxyError ? error : null;
        const code = proxy?.code ?? ErrorCode.internalError;
        const status = proxy?.httpStatus ?? 200;
        const payload = asRecord(asRecord(request.body)?.payload);
        const imagePayloadPresent =
          typeof payload?.imageBase64 === 'string' &&
          (payload.imageBase64 as string).length > 64;
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
          providerResponsePresent: code !== ErrorCode.invalidRequest,
          parsedOk: false,
        });
        return reply.code(status).send(errorEnvelope(code));
      }
    },
  );
}

function isJson(contentType: unknown): boolean {
  if (typeof contentType !== 'string') return false;
  return contentType.toLowerCase().includes('application/json');
}
