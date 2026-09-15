import type { FastifyInstance } from 'fastify';
import type { AppCheckVerifier } from '../auth/app-check.js';
import { createAppCheckVerifier } from '../auth/app-check.js';
import { createAuthenticationService } from '../auth/create-auth.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, errorEnvelope, successEnvelope } from '../errors.js';
import { requireAppCheck } from '../middleware/app-check.js';
import { requireAuth } from '../middleware/auth.js';
import type { ReadingNotificationTokens } from '../reading/reading-notifications.js';

export async function registerReadingNotificationRoutes(
  app: FastifyInstance,
  config: AppConfig,
  options: { appCheck?: AppCheckVerifier; tokens?: ReadingNotificationTokens },
): Promise<void> {
  const auth = requireAuth(createAuthenticationService(config));
  const appCheck = requireAppCheck(options.appCheck ?? createAppCheckVerifier(config));
  app.post(
    '/v1/reading-notifications/token',
    { preHandler: [auth, appCheck] },
    async (request, reply) => {
      if (!options.tokens || !request.identityKey) {
        return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
      }
      const token = (request.body as { token?: unknown } | null)?.token;
      if (typeof token !== 'string' || token.length < 20 || token.length > 4096) {
        return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      await options.tokens.register(request.identityKey, token);
      return reply.code(200).send(successEnvelope({ registered: true }));
    },
  );

  // R2.1 — explicit sign-out cleanup. Deliberately takes no token in the
  // body: ownership comes only from verified auth (same discipline as
  // registration above), and the server already knows which token (if
  // any) is registered for this identity — so the client never needs to
  // resend/log the raw token value just to unregister it. Idempotent:
  // unregistering an already-absent token still returns success.
  app.post(
    '/v1/reading-notifications/token/unregister',
    { preHandler: [auth, appCheck] },
    async (request, reply) => {
      if (!options.tokens || !request.identityKey) {
        return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
      }
      await options.tokens.unregister(request.identityKey);
      return reply.code(200).send(successEnvelope({ unregistered: true }));
    },
  );
}
