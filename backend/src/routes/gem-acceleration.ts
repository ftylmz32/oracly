/**
 * Authenticated acceleration and balance. No client-chosen cost or refund.
 */
import type { FastifyInstance, FastifyReply } from 'fastify';
import { createHash } from 'node:crypto';
import type { AppCheckVerifier } from '../auth/app-check.js';
import { createAppCheckVerifier } from '../auth/app-check.js';
import { createAuthenticationService } from '../auth/create-auth.js';
import type { AppConfig } from '../config.js';
import type { ReadingTaskScheduler } from '../reading/reading-task-scheduler.js';
import type { ReadingOperationRepository } from '../reading/operation-repository.js';
import type { ReadingStagedImageRepository } from '../reading/operation-staged-image-repository.js';
import { COFFEE_V2_SLOTS } from '../reading/operation-staged-image-model.js';
import { ErrorCode, errorEnvelope, successEnvelope } from '../errors.js';
import { logSafe } from '../logging.js';
import { requireAppCheck } from '../middleware/app-check.js';
import { requireAuth } from '../middleware/auth.js';
import type { ServerClock } from '../reading/clock.js';
import { toEpochMs } from '../reading/clock.js';
import { systemClock } from '../reading/clock.js';
import { GemLedger, GemLedgerError, parseIdempotency } from '../reading/gem-ledger.js';
import { toPublicStatus } from '../reading/operation-model.js';
import {
  GEM_DAILY_REWARD,
  GEM_STARTER_GRANT,
  GEM_TAROT_READING_COST,
  serverDayKey,
} from '../reading/gem-wallet-policy.js';

const FORBIDDEN = [
  'amount',
  'cost',
  'gems',
  'balance',
  'ownerUserId',
  'userId',
  'user_id',
  'sub',
  'readyAt',
  'status',
  'resultId',
  'premium',
  'refundAmount',
  'transactionId',
] as const;

export type GemRouteOptions = {
  appCheck?: AppCheckVerifier;
  ledger?: GemLedger;
  clock?: ServerClock;
  scheduler?: ReadingTaskScheduler;
  operationRepository?: ReadingOperationRepository;
  stagedImageRepository?: ReadingStagedImageRepository;
};

export async function registerGemAccelerationRoutes(
  app: FastifyInstance,
  config: AppConfig,
  options: GemRouteOptions = {},
): Promise<void> {
  const auth = requireAuth(createAuthenticationService(config));
  const appCheck = requireAppCheck(
    options.appCheck ?? createAppCheckVerifier(config),
  );
  const ledger = options.ledger;
  const clock = options.clock ?? systemClock();

  app.post(
    '/v1/reading-operations/:operationId/accelerate',
    { preHandler: [auth, appCheck] },
    async (request, reply) => {
      const owner = request.identityKey;
      if (!owner) {
        return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
      }
      if (!ledger) {
        return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
      }
      const operationId = (request.params as { operationId?: unknown }).operationId;
      const parsed = parseAccelerateBody(request.body);
      if (typeof operationId !== 'string' || !parsed) {
        return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      try {
        if (options.operationRepository && options.stagedImageRepository) {
          const operation = await options.operationRepository.getById(operationId);
          if (
            operation?.ownerUserId === owner &&
            (operation.readingType === 'coffee' || operation.readingType === 'palm')
          ) {
            const staged = await options.stagedImageRepository.get(operationId, owner);
            const validLegacy = staged?.uploadState === 'complete';
            const validCoffeeV2 = operation.readingType === 'coffee' && !staged
              ? validCompletedCoffeeV2Slots(
                  await options.stagedImageRepository.listSlots(operationId, owner),
                  operationId,
                  owner,
                )
              : false;
            if (!validLegacy && !validCoffeeV2) {
              // Never commit a Gem debit for an operation whose durable
              // source is absent/incomplete. This is the exact live-failure
              // boundary that previously allowed a charge followed by a
              // guaranteed claim failure.
              return reply.code(409).send(errorEnvelope(ErrorCode.invalidRequest));
            }
          }
        }
        const result = await ledger.accelerate({
          ownerUserId: owner,
          operationId,
          idempotencyKey: parsed.idempotencyKey,
          expectedPriceToken: parsed.expectedPriceToken ?? undefined,
        });
        if (
          options.scheduler &&
          (result.outcome === 'accelerated' || result.outcome === 'already_accelerated')
        ) {
          await options.scheduler.schedule({
            operationId,
            atMs: toEpochMs(clock.now()),
            trigger: 'accelerated',
          });
        }
        logSafe(request.log, 'info', 'reading_operation_accelerated', {
          requestId: request.requestId,
          operation: 'gem_acceleration',
          identityPresent: true,
          status: 200,
        });
        return reply.code(200).send(
          successEnvelope({
            outcome: result.outcome,
            idempotent: result.idempotent,
            balance: result.balance,
            canonicalCost: result.canonicalCost,
            priceToken: result.priceToken,
            operation: toPublicStatus(result.operation, toEpochMs(clock.now())),
          }),
        );
      } catch (error) {
        return sendLedgerError(reply, error);
      }
    },
  );

  app.get(
    '/v1/reading-operations/:operationId/accelerate',
    { preHandler: [auth, appCheck] },
    async (request, reply) => {
      const owner = request.identityKey;
      if (!owner) {
        return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
      }
      if (!ledger) {
        return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
      }
      const operationId = (request.params as { operationId?: unknown }).operationId;
      if (typeof operationId !== 'string') {
        return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      try {
        const quote = await ledger.quoteAcceleration({ ownerUserId: owner, operationId });
        if (!quote) {
          return reply.code(404).send(errorEnvelope(ErrorCode.invalidRequest));
        }
        return reply.code(200).send(
          successEnvelope({
            canonicalCost: quote.cost,
            balance: quote.balance,
            priceToken: quote.priceToken,
            payable: quote.payable,
          }),
        );
      } catch {
        return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
      }
    },
  );

  app.get(
    '/v1/gems/balance',
    { preHandler: [auth, appCheck] },
    async (request, reply) => {
      const owner = request.identityKey;
      if (!owner) {
        return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
      }
      if (!ledger) {
        return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
      }
      try {
        const balance = await ledger.balanceOf(owner);
        return reply.code(200).send(successEnvelope({ balance }));
      } catch {
        return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
      }
    },
  );

  app.post(
    '/v1/gems/starter-grant',
    { preHandler: [auth, appCheck] },
    async (request, reply) => {
      const owner = request.identityKey;
      if (!owner) return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
      if (!ledger) return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
      if (!parsePurposeBody(request.body)) {
        return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      try {
        const result = await ledger.credit({
          ownerUserId: owner,
          amount: GEM_STARTER_GRANT,
          idempotencyKey: 'starter-grant-v1',
          reason: 'starter_grant',
        });
        return reply.code(200).send(successEnvelope({
          balance: result.balance,
          granted: !result.idempotent,
          idempotent: result.idempotent,
          transactionId: result.transactionId,
        }));
      } catch (error) {
        return sendLedgerError(reply, error);
      }
    },
  );

  app.post(
    '/v1/gems/daily-reward',
    { preHandler: [auth, appCheck] },
    async (request, reply) => {
      const owner = request.identityKey;
      if (!owner) return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
      if (!ledger) return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
      if (!parsePurposeBody(request.body)) {
        return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      const day = serverDayKey(clock.now());
      try {
        const result = await ledger.credit({
          ownerUserId: owner,
          amount: GEM_DAILY_REWARD,
          idempotencyKey: `daily:${day}`,
          reason: 'daily_reward',
        });
        return reply.code(200).send(successEnvelope({
          balance: result.balance,
          granted: !result.idempotent,
          idempotent: result.idempotent,
          serverDay: day,
          transactionId: result.transactionId,
        }));
      } catch (error) {
        return sendLedgerError(reply, error);
      }
    },
  );

  app.post(
    '/v1/gems/tarot/:operationId/settle',
    { preHandler: [auth, appCheck] },
    async (request, reply) => {
      const owner = request.identityKey;
      if (!owner) return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
      if (!ledger) return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
      const operationId = (request.params as { operationId?: unknown }).operationId;
      if (typeof operationId !== 'string' || !parsePurposeBody(request.body)) {
        return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      const canonicalKey = `tarot:${createHash('sha256').update(operationId).digest('hex').slice(0, 48)}`;
      try {
        const result = await ledger.debit({
          ownerUserId: owner,
          amount: GEM_TAROT_READING_COST,
          idempotencyKey: canonicalKey,
          operationId,
          reason: 'tarot_reading',
        });
        return reply.code(200).send(successEnvelope({
          balance: result.balance,
          settled: true,
          idempotent: result.idempotent,
          canonicalCost: GEM_TAROT_READING_COST,
          transactionId: result.transactionId,
        }));
      } catch (error) {
        return sendLedgerError(reply, error);
      }
    },
  );
}

function validCompletedCoffeeV2Slots(
  records: Awaited<ReturnType<ReadingStagedImageRepository['listSlots']>>,
  operationId: string,
  ownerUserId: string,
): boolean {
  if (records.length !== COFFEE_V2_SLOTS.length) return false;
  const slots = new Set(records.map((record) => record.slot));
  return COFFEE_V2_SLOTS.every((slot) => slots.has(slot)) && records.every((record) =>
    record.operationId === operationId &&
    record.ownerUserId === ownerUserId &&
    record.readingType === 'coffee' &&
    record.uploadState === 'complete' &&
    record.slot != null,
  );
}

const PRICE_TOKEN = /^[a-f0-9]{8,64}$/;

function parseAccelerateBody(
  body: unknown,
): { idempotencyKey: string; expectedPriceToken: string | null } | null {
  if (!body || typeof body !== 'object' || Array.isArray(body)) return null;
  const record = body as Record<string, unknown>;
  for (const key of FORBIDDEN) {
    if (Object.prototype.hasOwnProperty.call(record, key)) return null;
  }
  const idempotencyKey = parseIdempotency(record.idempotencyKey);
  if (!idempotencyKey) return null;
  // Echo of what the user's quote showed -- never trusted as the charged
  // amount itself, only compared against the server's own fresh cost.
  const rawToken = record.expectedPriceToken;
  if (rawToken != null && (typeof rawToken !== 'string' || !PRICE_TOKEN.test(rawToken))) {
    return null;
  }
  return { idempotencyKey, expectedPriceToken: (rawToken as string | undefined) ?? null };
}

function parsePurposeBody(body: unknown): string | null {
  if (!body || typeof body !== 'object' || Array.isArray(body)) return null;
  const record = body as Record<string, unknown>;
  for (const key of FORBIDDEN) {
    if (Object.prototype.hasOwnProperty.call(record, key)) return null;
  }
  if (Object.keys(record).some((key) => key !== 'idempotencyKey')) return null;
  return parseIdempotency(record.idempotencyKey);
}

function sendLedgerError(reply: FastifyReply, error: unknown) {
  if (error instanceof GemLedgerError) {
    if (error.code === 'insufficient_gems') {
      return reply.code(409).send(errorEnvelope(ErrorCode.insufficientGems));
    }
    if (error.code === 'already_ready') {
      return reply.code(409).send(errorEnvelope(ErrorCode.invalidRequest));
    }
    if (error.code === 'already_accelerated') {
      return reply.code(409).send(errorEnvelope(ErrorCode.invalidRequest));
    }
    if (error.code === 'not_found') {
      return reply.code(404).send(errorEnvelope(ErrorCode.invalidRequest));
    }
    if (error.code === 'invalid') {
      return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
    }
    if (error.code === 'unavailable') {
      return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
    }
    return reply.code(409).send(errorEnvelope(ErrorCode.invalidRequest));
  }
  return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
}
