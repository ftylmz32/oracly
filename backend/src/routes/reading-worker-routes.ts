import { OAuth2Client } from 'google-auth-library';
import type { FastifyInstance, FastifyRequest } from 'fastify';
import type { AppCheckVerifier } from '../auth/app-check.js';
import { createAppCheckVerifier } from '../auth/app-check.js';
import { createAuthenticationService } from '../auth/create-auth.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, errorEnvelope, successEnvelope } from '../errors.js';
import { requireAppCheck } from '../middleware/app-check.js';
import { requireAuth } from '../middleware/auth.js';
import type { ReadingProcessor } from '../reading/reading-processor.js';
import type { ReadingResultRepository } from '../reading/reading-result-repository.js';
import type { SoulmatePortraitStore } from '../reading/soulmate-portrait-store.js';
import {
  logWorkerFailure,
  logWorkerStage,
  ReadingWorkerFailure,
} from '../reading/reading-worker-telemetry.js';

export type ReadingWorkerRouteOptions = {
  processor?: ReadingProcessor;
  results?: ReadingResultRepository;
  appCheck?: AppCheckVerifier;
  verifyTask?: (request: FastifyRequest) => Promise<boolean>;
  /** SMD1 — durable Soulmate portrait storage, for the authenticated fetch route below. */
  soulmatePortraits?: SoulmatePortraitStore;
};

export async function registerReadingWorkerRoutes(
  app: FastifyInstance,
  config: AppConfig,
  options: ReadingWorkerRouteOptions,
): Promise<void> {
  app.post('/internal/reading-tasks/process', async (request, reply) => {
    if (!options.processor || !(await (options.verifyTask ?? verifyCloudTask(config))(request))) {
      return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
    }
    logWorkerStage(request.log, 'reading_task_auth_verified', {});
    const body = request.body as { operationId?: unknown } | null;
    if (!body || typeof body.operationId !== 'string') {
      return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
    }
    try {
      const outcome = await options.processor.process(body.operationId, request.log);
      return reply.code(200).send(successEnvelope({ outcome }));
    } catch (error) {
      const failure =
        error instanceof ReadingWorkerFailure
          ? error
          : new ReadingWorkerFailure('worker', 'internal_error', true, 'unknown', error);
      logWorkerFailure(request.log, {
        operationId: body.operationId,
        feature: failure.feature,
        stage: failure.stage,
        error: failure,
        retryable: failure.retryable,
      });
      // Non-2xx so Cloud Tasks retries the SAME task for retryable failures.
      return reply.code(failure.retryable ? 503 : 500).send(errorEnvelope(ErrorCode.internalError));
    }
  });

  const auth = requireAuth(createAuthenticationService(config));
  const appCheck = requireAppCheck(options.appCheck ?? createAppCheckVerifier(config));
  app.get(
    '/v1/reading-operations/:operationId/result',
    { preHandler: [auth, appCheck] },
    async (request, reply) => {
      if (!options.results || !request.identityKey) {
        return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
      }
      const operationId = (request.params as { operationId?: unknown }).operationId;
      if (typeof operationId !== 'string') {
        return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      const result = await options.results.get(operationId);
      if (!result || result.ownerUserId !== request.identityKey) {
        return reply.code(404).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      return reply.code(200).send(successEnvelope({
        operationId: result.operationId,
        resultId: result.resultId,
        readingType: result.readingType,
        persistedAt: new Date(result.persistedAtMs).toISOString(),
        result: result.data,
      }));
    },
  );

  // SMD1 — the durably-generated Soulmate portrait, private and
  // authenticated. `SoulmatePortraitStore.get` already returns null for
  // BOTH "no such portrait" and "exists but belongs to someone else" —
  // this route can never leak whether another user's portrait exists.
  app.get(
    '/v1/reading-operations/:operationId/soulmate-portrait',
    { preHandler: [auth, appCheck] },
    async (request, reply) => {
      if (!options.soulmatePortraits || !request.identityKey) {
        return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
      }
      const operationId = (request.params as { operationId?: unknown }).operationId;
      if (typeof operationId !== 'string') {
        return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      const portrait = await options.soulmatePortraits.get(operationId, request.identityKey);
      if (!portrait) {
        return reply.code(404).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      return reply.code(200).send(successEnvelope({
        operationId,
        mimeType: portrait.contentType,
        imageBase64: portrait.bytes.toString('base64'),
      }));
    },
  );
}

export type GoogleOidcVerifier = Pick<OAuth2Client, 'verifyIdToken'>;

export function verifyCloudTask(
  config: AppConfig,
  oauth: GoogleOidcVerifier = new OAuth2Client(),
) {
  return async (request: FastifyRequest): Promise<boolean> => {
    const raw = request.headers.authorization;
    const token = typeof raw === 'string' && raw.startsWith('Bearer ')
      ? raw.slice('Bearer '.length)
      : null;
    if (!token || !config.readingTaskAudience || !config.readingTaskServiceAccount) {
      return false;
    }
    const jwtParts = token.split('.');
    const signaturePresent = jwtParts.length === 3 && jwtParts[2]!.length > 0;
    if (!signaturePresent) return false;
    try {
      const ticket = await oauth.verifyIdToken({
        idToken: token,
        audience: config.readingTaskAudience,
      });
      const payload = ticket.getPayload();
      const accepted = Boolean(
        payload &&
          (payload.iss === 'https://accounts.google.com' ||
            payload.iss === 'accounts.google.com') &&
          payload.aud === config.readingTaskAudience &&
          payload.email_verified === true &&
          payload.email === config.readingTaskServiceAccount,
      );
      if (accepted && payload) {
        request.log.info({
          event: 'reading_task_oidc_verified',
          oidcIssuer: payload.iss,
          oidcAudience: payload.aud,
          oidcEmail: payload.email,
          oidcEmailVerified: payload.email_verified,
          oidcSubject: payload.sub,
          oidcSignaturePresent: signaturePresent,
        });
      }
      return accepted;
    } catch {
      return false;
    }
  };
}
