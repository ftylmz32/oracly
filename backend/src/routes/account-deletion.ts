import type { FastifyInstance } from 'fastify';
import { createAuthenticationService } from '../auth/create-auth.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, errorEnvelope, successEnvelope } from '../errors.js';
import { requireAuth } from '../middleware/auth.js';
import { createAppCheckVerifier, type AppCheckVerifier } from '../auth/app-check.js';
import { requireAppCheck } from '../middleware/app-check.js';
import { createAccountDeletionRepository, type AccountDeletionRepository } from '../account/account-deletion.js';

export async function registerAccountDeletionRoute(app: FastifyInstance, config: AppConfig, options: {
  repository?: AccountDeletionRepository; appCheck?: AppCheckVerifier;
} = {}): Promise<void> {
  const auth = requireAuth(createAuthenticationService(config));
  const appCheck = requireAppCheck(options.appCheck ?? createAppCheckVerifier(config));
  const repository = options.repository ?? createAccountDeletionRepository(config);
  app.post('/v1/account/deletion', { preHandler: [auth, appCheck] }, async (request, reply) => {
    // Deliberately no UID in the request body: ownership comes only from verified auth.
    if (!request.identityKey) return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
    try {
      return reply.code(202).send(successEnvelope(await repository.deleteForIdentity(request.identityKey)));
    } catch {
      return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
    }
  });
}
