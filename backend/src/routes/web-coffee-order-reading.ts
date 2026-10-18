import { randomBytes } from 'node:crypto';
import type { FastifyInstance, FastifyReply } from 'fastify';
import type { AppCheckVerifier } from '../auth/app-check.js';
import { createAuthenticationService } from '../auth/create-auth.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, errorEnvelope, successEnvelope } from '../errors.js';
import { requireAppCheck } from '../middleware/app-check.js';
import { requireAuth } from '../middleware/auth.js';
import { sanitizeCoffeeIntention } from '../reading/coffee-intention.js';
import { systemClock, toEpochMs, type ServerClock } from '../reading/clock.js';
import { parseSourceRequestId, SCHEMA_VERSION, toPublicStatus, type ReadingOperationRecord } from '../reading/operation-model.js';
import { resolveWaitMs, provisionalWaitPolicy, type WaitPolicy } from '../reading/wait-policy.js';
import {
  createWebCoffeeOrderReadingRepository,
  WebOrderReadingError,
  type WebCoffeeOrderReadingRepository,
} from '../reading/web-coffee-order-reading-repository.js';
import { isConfiguredWebApp } from '../auth/web-app-check.js';

const ORDER_ID = /^[A-Za-z0-9_-]{8,80}$/;

export type WebCoffeeOrderReadingRouteOptions = {
  appCheck: AppCheckVerifier;
  repository?: WebCoffeeOrderReadingRepository;
  clock?: ServerClock;
  policy?: WaitPolicy;
  newOperationId?: () => string;
};

export async function registerWebCoffeeOrderReadingRoute(
  app: FastifyInstance,
  config: AppConfig,
  options: WebCoffeeOrderReadingRouteOptions,
): Promise<void> {
  const auth = requireAuth(createAuthenticationService(config));
  const appCheck = requireAppCheck(options.appCheck);
  const repository = options.repository ?? createWebCoffeeOrderReadingRepository(config);
  const clock = options.clock ?? systemClock();
  const policy = options.policy ?? provisionalWaitPolicy();

  app.post('/v1/web/coffee-orders/:orderId/reading-operation',
    { preHandler: [auth, appCheck] },
    async (request, reply) => {
      if (!config.webCoffeeOrderReadingEnabled || !config.coffeeV3CreationEnabled || options.appCheck.mode !== 'verify' ||
          !isConfiguredWebApp(request.appCheckAppId, config)) {
        return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
      }
      const uid = request.authSubject;
      const owner = request.identityKey;
      const orderId = (request.params as { orderId?: unknown }).orderId;
      const body = parseBody(request.body);
      if (!uid || !owner || typeof orderId !== 'string' || !ORDER_ID.test(orderId) || !body) {
        return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      const nowMs = toEpochMs(clock.now());
      const record: ReadingOperationRecord = {
        schemaVersion: SCHEMA_VERSION,
        operationId: (options.newOperationId ?? randomOperationId)(),
        ownerUserId: owner,
        readingType: 'coffee',
        language: 'tr',
        status: 'waiting',
        createdAtMs: nowMs,
        readyAtMs: nowMs + resolveWaitMs('coffee', policy),
        updatedAtMs: nowMs,
        sourceRequestId: body.sourceRequestId,
        resultId: null,
        failureCode: null,
        acceleratedAtMs: null,
        gemDebitId: null,
        executionStartedAtMs: null,
        executionMode: null,
        coffeeIntention: body.intention,
        coffeeInputContract: 'trusted_intention_v1',
        coffeeCaptureContract: 'three_view_v3',
      };
      try {
        const stored = await repository.createFromEntitlement({ orderId, firebaseUid: uid, record });
        return reply.code(200).send(successEnvelope(toPublicStatus(stored.record, nowMs)));
      } catch (error) {
        return sendError(reply, error);
      }
    });
}

function parseBody(value: unknown): { sourceRequestId: string; intention: string } | null {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const body = value as Record<string, unknown>;
  const allowed = new Set(['readingType', 'sourceRequestId', 'language', 'intention', 'coffeeInputContract', 'coffeeCaptureContract']);
  if (Object.keys(body).some((key) => !allowed.has(key))) return null;
  if (body.readingType !== 'coffee' || body.language !== 'tr' ||
      body.coffeeInputContract !== 'trusted_intention_v1' ||
      body.coffeeCaptureContract !== 'three_view_v3') return null;
  const sourceRequestId = parseSourceRequestId(body.sourceRequestId);
  const intention = sanitizeCoffeeIntention(body.intention);
  return sourceRequestId && intention ? { sourceRequestId, intention } : null;
}

function sendError(reply: FastifyReply, error: unknown) {
  if (error instanceof WebOrderReadingError) {
    if (error.code === 'wrong_owner') return reply.code(404).send(errorEnvelope(ErrorCode.invalidRequest));
    if (error.code === 'not_entitled' || error.code === 'conflict') return reply.code(409).send(errorEnvelope(ErrorCode.invalidRequest));
    if (error.code === 'rate_limited') return reply.code(429).send(errorEnvelope(ErrorCode.rateLimited));
  }
  return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
}

function randomOperationId(): string {
  return randomBytes(16).toString('hex');
}
