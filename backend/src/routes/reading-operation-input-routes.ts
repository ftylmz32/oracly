/**
 * Save/read a ReadingOperation's structured input (BATCH 5G — Soulmate
 * needs to durably remember name/birth/gender/intention across an app
 * kill so a recovered operation can still run its pipeline). No AI call
 * happens here. Mirrors reading-operations.ts's own-default-on-absence
 * pattern deliberately: BATCH 5F found that routes without an internal
 * fallback (reading-flow-routes.ts) silently 503'd forever because
 * index.ts never passed the option through — these routes must not repeat
 * that failure class.
 */
import type { FastifyInstance } from 'fastify';
import type { AppCheckVerifier } from '../auth/app-check.js';
import { createAppCheckVerifier } from '../auth/app-check.js';
import { createAuthenticationService } from '../auth/create-auth.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, errorEnvelope, successEnvelope } from '../errors.js';
import { requireAppCheck } from '../middleware/app-check.js';
import { requireAuth } from '../middleware/auth.js';
import { systemClock, type ServerClock } from '../reading/clock.js';
import {
  createReadingOperationInputRepository,
  type ReadingOperationInputRepository,
} from '../reading/operation-input-repository.js';
import { ReadingOperationInputService } from '../reading/operation-input-service.js';
import {
  createReadingOperationRepository,
  type ReadingOperationRepository,
} from '../reading/operation-repository.js';
import { ReadingOperationError, ReadingOperationService } from '../reading/operation-service.js';
import { provisionalWaitPolicy, type WaitPolicy } from '../reading/wait-policy.js';
import type { ReadingTaskScheduler } from '../reading/reading-task-scheduler.js';

export type ReadingOperationInputRouteOptions = {
  appCheck?: AppCheckVerifier;
  inputRepository?: ReadingOperationInputRepository;
  operationRepository?: ReadingOperationRepository;
  clock?: ServerClock;
  policy?: WaitPolicy;
  /** SMD1 — schedules the durable worker once a `durable` Soulmate
   * operation's input has been saved. Absent/undefined: unchanged
   * behavior (no scheduling attempted), matching every pre-SMD1 client. */
  scheduler?: ReadingTaskScheduler;
};

export async function registerReadingOperationInputRoutes(
  app: FastifyInstance,
  config: AppConfig,
  options: ReadingOperationInputRouteOptions = {},
): Promise<void> {
  const auth = requireAuth(createAuthenticationService(config));
  const appCheck = requireAppCheck(
    options.appCheck ?? createAppCheckVerifier(config),
  );
  const clock = options.clock ?? systemClock();
  const operations = new ReadingOperationService(
    options.operationRepository ?? createReadingOperationRepository(config),
    clock,
    options.policy ?? provisionalWaitPolicy(),
  );
  const inputs = new ReadingOperationInputService(
    options.inputRepository ?? createReadingOperationInputRepository(config),
    operations,
    clock,
  );

  app.post(
    '/v1/reading-operations/:operationId/input',
    { preHandler: [auth, appCheck] },
    async (request, reply) => {
      const owner = request.identityKey;
      if (!owner) return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
      const operationId = (request.params as { operationId?: unknown }).operationId;
      if (typeof operationId !== 'string') {
        return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      const body = request.body;
      if (!body || typeof body !== 'object' || Array.isArray(body)) {
        return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      try {
        await inputs.save({ ownerUserId: owner, operationId, fields: body });
        // SMD1 — the input is the last thing a durable Soulmate submission
        // needs before it can run; this is the direct analog of Coffee/
        // Palm's staged-image-upload trigger. A legacy (executionMode
        // absent) Soulmate operation, or any Coffee/Palm operation, never
        // reaches this branch and schedules nothing here — unchanged.
        if (options.scheduler) {
          const operation = await operations.get(owner, operationId);
          if (operation.readingType === 'soulmate' && operation.executionMode === 'durable') {
            await options.scheduler.schedule({
              operationId,
              atMs: operation.readyAtMs,
              trigger: 'ready',
            });
          }
        }
        return reply.code(200).send(successEnvelope({ saved: true }));
      } catch (error) {
        return sendInputError(reply, error);
      }
    },
  );

  app.get(
    '/v1/reading-operations/:operationId/input',
    { preHandler: [auth, appCheck] },
    async (request, reply) => {
      const owner = request.identityKey;
      if (!owner) return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
      const operationId = (request.params as { operationId?: unknown }).operationId;
      if (typeof operationId !== 'string') {
        return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      try {
        const fields = await inputs.get(owner, operationId);
        return reply.code(200).send(successEnvelope({ fields: fields ?? null }));
      } catch (error) {
        return sendInputError(reply, error);
      }
    },
  );
}

function sendInputError(
  reply: { code: (n: number) => { send: (b: unknown) => unknown } },
  error: unknown,
) {
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
