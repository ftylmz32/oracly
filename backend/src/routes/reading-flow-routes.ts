/**
 * Claim, complete, fail, and recover one logical reading.
 * Does not run Coffee, Palm, or Soulmate models.
 */
import type { FastifyInstance } from 'fastify';
import type { AppCheckVerifier } from '../auth/app-check.js';
import { createAppCheckVerifier } from '../auth/app-check.js';
import { createAuthenticationService } from '../auth/create-auth.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, errorEnvelope, successEnvelope } from '../errors.js';
import { requireAppCheck } from '../middleware/app-check.js';
import { requireAuth } from '../middleware/auth.js';
import type { ServerClock } from '../reading/clock.js';
import { toEpochMs } from '../reading/clock.js';
import { systemClock } from '../reading/clock.js';
import { parseResultId, toPublicStatus } from '../reading/operation-model.js';
import { ReadingOperationError } from '../reading/operation-service.js';
import {
  parseReadingTypeQuery,
  type ReadingFlow,
} from '../reading/reading-flow.js';
import type { ReadingStagedImageService } from '../reading/operation-staged-image-service.js';

const FORBIDDEN = [
  'ownerUserId',
  'userId',
  'readyAt',
  'status',
  'amount',
  'refundAmount',
  'premium',
] as const;

export async function registerReadingFlowRoutes(
  app: FastifyInstance,
  config: AppConfig,
  options: {
    appCheck?: AppCheckVerifier;
    flow?: ReadingFlow;
    clock?: ServerClock;
    stagedImages?: ReadingStagedImageService;
  } = {},
): Promise<void> {
  const auth = requireAuth(createAuthenticationService(config));
  const appCheck = requireAppCheck(
    options.appCheck ?? createAppCheckVerifier(config),
  );
  const clock = options.clock ?? systemClock();

  app.get(
    '/v1/reading-flow/active',
    { preHandler: [auth, appCheck] },
    async (request, reply) => {
      const owner = request.identityKey;
      const flow = options.flow;
      if (!owner) return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
      if (!flow) return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
      const readingType = parseReadingTypeQuery(
        (request.query as { readingType?: unknown }).readingType,
      );
      if (!readingType) return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      try {
        const record = await flow.active(owner, readingType);
        return reply.code(200).send(
          successEnvelope({
            operation: record
              ? toPublicStatus(record, toEpochMs(clock.now()))
              : null,
          }),
        );
      } catch (error) {
        return sendFlowError(reply, error);
      }
    },
  );

  app.post(
    '/v1/reading-operations/:operationId/claim',
    { preHandler: [auth, appCheck] },
    async (request, reply) => {
      return handle(request, reply, options.flow, clock, async (flow, owner, operationId) => {
        const claimed = await flow.claim(owner, operationId);
        if (
          claimed.execute &&
          (claimed.operation.readingType === 'coffee' ||
            claimed.operation.readingType === 'palm')
        ) {
          try {
            await options.stagedImages?.retrieveForProcessing({
              ownerUserId: owner,
              operationId,
              readingType: claimed.operation.readingType,
            });
            if (!options.stagedImages) throw new ReadingOperationError('unavailable');
          } catch (error) {
            // A claimed operation with no trustworthy staged input must never
            // reach the paid pipeline. Finalize through the existing failure
            // path (including its refund semantics) and fail closed.
            await flow.failFinal({ ownerUserId: owner, operationId });
            throw error;
          }
        }
        return {
          execute: claimed.execute,
          operation: toPublicStatus(claimed.operation, toEpochMs(clock.now())),
        };
      });
    },
  );

  app.post(
    '/v1/reading-operations/:operationId/complete',
    { preHandler: [auth, appCheck] },
    async (request, reply) => {
      const body = request.body;
      if (!isPlain(body) || hasForbidden(body)) {
        return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      const resultId = parseResultId(body.resultId);
      if (!resultId) return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      return handle(request, reply, options.flow, clock, async (flow, owner, operationId) => {
        const record = await flow.complete({ ownerUserId: owner, operationId, resultId });
        // Completion means the client has durably persisted and attached its
        // canonical result. Cleanup is intentionally best-effort.
        if (record.readingType === 'coffee' || record.readingType === 'palm') {
          await options.stagedImages?.delete({ ownerUserId: owner, operationId });
        }
        return { operation: toPublicStatus(record, toEpochMs(clock.now())) };
      });
    },
  );

  app.post(
    '/v1/reading-operations/:operationId/fail',
    { preHandler: [auth, appCheck] },
    async (request, reply) => {
      if (request.body != null && (!isPlain(request.body) || hasForbidden(request.body))) {
        return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      return handle(request, reply, options.flow, clock, async (flow, owner, operationId) => {
        const record = await flow.failFinal({ ownerUserId: owner, operationId });
        return {
          operation: toPublicStatus(record, toEpochMs(clock.now())),
          refunded: record.gemDebitId != null && record.status === 'failed',
        };
      });
    },
  );
}

async function handle(
  request: { identityKey?: string; params: unknown },
  reply: { code: (n: number) => { send: (b: unknown) => unknown } },
  flow: ReadingFlow | undefined,
  _clock: ServerClock,
  run: (
    flow: ReadingFlow,
    owner: string,
    operationId: string,
  ) => Promise<Record<string, unknown>>,
) {
  const owner = request.identityKey;
  if (!owner) return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
  if (!flow) return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
  const operationId = (request.params as { operationId?: unknown }).operationId;
  if (typeof operationId !== 'string') {
    return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
  }
  try {
    return reply.code(200).send(successEnvelope(await run(flow, owner, operationId)));
  } catch (error) {
    return sendFlowError(reply, error);
  }
}

function sendFlowError(
  reply: { code: (n: number) => { send: (b: unknown) => unknown } },
  error: unknown,
) {
  if (error instanceof ReadingOperationError) {
    if (error.code === 'not_found') {
      return reply.code(404).send(errorEnvelope(ErrorCode.invalidRequest));
    }
    if (error.code === 'unavailable') {
      return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
    }
    return reply.code(409).send(errorEnvelope(ErrorCode.invalidRequest));
  }
  return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
}

function isPlain(body: unknown): body is Record<string, unknown> {
  return !!body && typeof body === 'object' && !Array.isArray(body);
}

function hasForbidden(body: Record<string, unknown>): boolean {
  return FORBIDDEN.some((key) => Object.prototype.hasOwnProperty.call(body, key));
}
