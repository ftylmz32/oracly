/**
 * BATCH 5I — durable Coffee/Palm image staging. The client never sends
 * (and this route never trusts) an ownerUserId, bucket name, objectPath,
 * or GCS URL — all of those are server-derived from the authenticated
 * identity and the existing ReadingOperation. Mirrors the same
 * own-default-on-absence pattern as reading-operation-input-routes.ts.
 */
import type { FastifyInstance } from 'fastify';
import type { AppCheckVerifier } from '../auth/app-check.js';
import { createAppCheckVerifier } from '../auth/app-check.js';
import { createAuthenticationService } from '../auth/create-auth.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, ProxyError, errorEnvelope, successEnvelope } from '../errors.js';
import { requireAppCheck } from '../middleware/app-check.js';
import { requireAuth } from '../middleware/auth.js';
import { systemClock, type ServerClock } from '../reading/clock.js';
import {
  createReadingStagedImageRepository,
  type ReadingStagedImageRepository,
} from '../reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../reading/operation-staged-image-service.js';
import {
  createReadingOperationRepository,
  type ReadingOperationRepository,
} from '../reading/operation-repository.js';
import { ReadingOperationError, ReadingOperationService } from '../reading/operation-service.js';
import {
  createReadingStagedObjectStore,
  type ReadingStagedObjectStore,
} from '../reading/staged-object-store.js';
import { provisionalWaitPolicy, type WaitPolicy } from '../reading/wait-policy.js';
import type { ReadingTaskScheduler } from '../reading/reading-task-scheduler.js';

export type ReadingStagedImageRouteOptions = {
  appCheck?: AppCheckVerifier;
  stagedImageRepository?: ReadingStagedImageRepository;
  objectStore?: ReadingStagedObjectStore;
  operationRepository?: ReadingOperationRepository;
  clock?: ServerClock;
  policy?: WaitPolicy;
  /**
   * Pre-built service, shared with the AI proxy's retrieval path so both
   * see the same durable state — takes priority over the raw
   * repository/store options above when provided.
   */
  stagedImages?: ReadingStagedImageService;
  scheduler?: ReadingTaskScheduler;
};

export async function registerReadingStagedImageRoutes(
  app: FastifyInstance,
  config: AppConfig,
  options: ReadingStagedImageRouteOptions = {},
): Promise<void> {
  const auth = requireAuth(createAuthenticationService(config));
  const appCheck = requireAppCheck(
    options.appCheck ?? createAppCheckVerifier(config),
  );
  const clock = options.clock ?? systemClock();
  const staged =
    options.stagedImages ??
    new ReadingStagedImageService(
      options.stagedImageRepository ?? createReadingStagedImageRepository(config),
      options.objectStore ?? createReadingStagedObjectStore(config),
      new ReadingOperationService(
        options.operationRepository ?? createReadingOperationRepository(config),
        clock,
        options.policy ?? provisionalWaitPolicy(),
      ),
      clock,
      config,
    );

  app.post(
    '/v1/reading-operations/:operationId/staged-image',
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
      const record = body as Record<string, unknown>;
      // Never accept a client-declared owner/path/bucket — the server
      // derives all of those; reject the request outright if present.
      if (
        Object.prototype.hasOwnProperty.call(record, 'ownerUserId') ||
        Object.prototype.hasOwnProperty.call(record, 'objectPath') ||
        Object.prototype.hasOwnProperty.call(record, 'bucket') ||
        Object.prototype.hasOwnProperty.call(record, 'url')
      ) {
        return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      try {
        const status = await staged.stage({
          ownerUserId: owner,
          operationId,
          mimeType: record.mimeType,
          imageBase64: record.imageBase64,
          handSide: record.handSide,
          slot: record.slot,
        });
        if (options.scheduler) {
          await options.scheduler.schedule({
            operationId: status.operationId,
            atMs: status.readyAtMs,
            trigger: 'ready',
          });
        }
        return reply.code(200).send(
          successEnvelope({
            operationId: status.operationId,
            staged: status.staged,
            contentType: status.contentType,
            byteSize: status.byteSize,
          }),
        );
      } catch (error) {
        return sendStagedImageError(reply, error);
      }
    },
  );
}

function sendStagedImageError(
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
  if (error instanceof ProxyError) {
    return reply.code(400).send(errorEnvelope(error.code));
  }
  return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
}
