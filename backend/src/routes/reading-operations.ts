/**
 * Authenticated reading-operation foundation.
 * Create once, recover status. No AI, no gem debit, no acceleration.
 */
import type { FastifyInstance, FastifyReply } from 'fastify';
import type { AppCheckVerifier } from '../auth/app-check.js';
import { createAppCheckVerifier } from '../auth/app-check.js';
import { createAuthenticationService } from '../auth/create-auth.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, errorEnvelope, successEnvelope } from '../errors.js';
import { logSafe } from '../logging.js';
import { requireAppCheck } from '../middleware/app-check.js';
import { requireAuth } from '../middleware/auth.js';
import { systemClock, type ServerClock } from '../reading/clock.js';
import { toEpochMs } from '../reading/clock.js';
import {
  isExecutionMode,
  isReadingType,
  isReadingLanguage,
  parseSourceRequestId,
  toPublicStatus,
  type ExecutionMode,
} from '../reading/operation-model.js';
import {
  createReadingOperationRepository,
  type ReadingOperationRepository,
} from '../reading/operation-repository.js';
import {
  ReadingOperationError,
  ReadingOperationService,
} from '../reading/operation-service.js';
import { provisionalWaitPolicy, type WaitPolicy } from '../reading/wait-policy.js';
import type { ReadingFlow } from '../reading/reading-flow.js';

const FORBIDDEN_BODY_KEYS = [
  'readyAt',
  'createdAt',
  'status',
  'resultId',
  'ownerUserId',
  'userId',
  'user_id',
  'sub',
  'acceleratedAt',
  'gemDebitId',
  'failureCode',
  'serverNow',
  'remainingMs',
  'clientNow',
  'elapsedMs',
] as const;

export type ReadingOperationRouteOptions = {
  appCheck?: AppCheckVerifier;
  repository?: ReadingOperationRepository;
  clock?: ServerClock;
  policy?: WaitPolicy;
  flow?: ReadingFlow;
};

export async function registerReadingOperationRoutes(
  app: FastifyInstance,
  config: AppConfig,
  options: ReadingOperationRouteOptions = {},
): Promise<void> {
  const auth = requireAuth(createAuthenticationService(config));
  const appCheck = requireAppCheck(
    options.appCheck ?? createAppCheckVerifier(config),
  );
  const service = new ReadingOperationService(
    options.repository ?? createReadingOperationRepository(config),
    options.clock ?? systemClock(),
    options.policy ?? provisionalWaitPolicy(),
  );

  app.post(
    '/v1/reading-operations',
    { preHandler: [auth, appCheck] },
    async (request, reply) => {
      const owner = request.identityKey;
      if (!owner) {
        return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
      }
      const parsed = parseCreateBody(request.body);
      if (!parsed.ok) {
        return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      try {
        const record = await service.create({
          ownerUserId: owner,
          readingType: parsed.readingType,
          sourceRequestId: parsed.sourceRequestId,
          language: parsed.language,
          executionMode: parsed.executionMode,
        });
        await options.flow?.remember(record);
        logSafe(request.log, 'info', 'reading_operation_created', {
          requestId: request.requestId,
          operation: 'reading_operation',
          identityPresent: true,
          status: 200,
        });
        return reply.code(200).send(
          successEnvelope(toPublicStatus(record, toEpochMs(serviceClock(options)))),
        );
      } catch (error) {
        return sendServiceError(reply, error);
      }
    },
  );

  app.get(
    '/v1/reading-operations/:operationId',
    { preHandler: [auth, appCheck] },
    async (request, reply) => {
      const owner = request.identityKey;
      if (!owner) {
        return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
      }
      const operationId = (request.params as { operationId?: unknown }).operationId;
      if (typeof operationId !== 'string') {
        return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      try {
        const record = await service.get(owner, operationId);
        return reply.code(200).send(
          successEnvelope(toPublicStatus(record, toEpochMs(serviceClock(options)))),
        );
      } catch (error) {
        return sendServiceError(reply, error);
      }
    },
  );
}

function serviceClock(options: ReadingOperationRouteOptions): Date {
  return (options.clock ?? systemClock()).now();
}

function parseCreateBody(body: unknown):
  | {
      ok: true;
      readingType: 'coffee' | 'palm' | 'soulmate';
      sourceRequestId: string;
      language: 'tr' | 'en' | 'ru';
      executionMode?: ExecutionMode;
    }
  | { ok: false } {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return { ok: false };
  }
  const record = body as Record<string, unknown>;
  for (const key of FORBIDDEN_BODY_KEYS) {
    if (Object.prototype.hasOwnProperty.call(record, key)) {
      return { ok: false };
    }
  }
  if (!isReadingType(record.readingType)) return { ok: false };
  // Backward compatibility for already-released clients predating R4.
  // New R4 clients always submit a validated locale.
  const language = record.language == null ? 'tr' : record.language;
  if (!isReadingLanguage(language)) return { ok: false };
  const sourceRequestId = parseSourceRequestId(record.sourceRequestId);
  if (!sourceRequestId) return { ok: false };
  // SMD1 — additive and optional, Soulmate-only. A pre-SMD1 client never
  // sends this key, so `executionMode` resolves to undefined -> legacy,
  // exactly as today. Coffee/Palm are already durable via their own
  // staged-image trigger and never need this flag.
  if (record.executionMode != null) {
    if (record.readingType !== 'soulmate' || !isExecutionMode(record.executionMode)) {
      return { ok: false };
    }
  }
  return {
    ok: true,
    readingType: record.readingType,
    sourceRequestId,
    language,
    executionMode: isExecutionMode(record.executionMode) ? record.executionMode : undefined,
  };
}

function sendServiceError(reply: FastifyReply, error: unknown) {
  if (error instanceof ReadingOperationError) {
    if (error.code === 'not_found' || error.code === 'forbidden') {
      return reply.code(404).send(errorEnvelope(ErrorCode.invalidRequest));
    }
    if (error.code === 'unavailable') {
      return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
    }
    return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
  }
  return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
}
