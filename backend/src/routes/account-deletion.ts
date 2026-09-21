import type { FastifyInstance } from 'fastify';
import { createAuthenticationService } from '../auth/create-auth.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, errorEnvelope, successEnvelope } from '../errors.js';
import { requireAuth } from '../middleware/auth.js';
import { createAppCheckVerifier, type AppCheckVerifier } from '../auth/app-check.js';
import { requireAppCheck } from '../middleware/app-check.js';
import { createAccountDeletionRepository, type AccountDeletionRepository } from '../account/account-deletion.js';
import { identityKeyFromSubject } from '../auth/identity.js';

export async function registerAccountDeletionRoute(app: FastifyInstance, config: AppConfig, options: {
  repository?: AccountDeletionRepository; appCheck?: AppCheckVerifier;
} = {}): Promise<void> {
  const auth = requireAuth(createAuthenticationService(config));
  const appCheck = requireAppCheck(options.appCheck ?? createAppCheckVerifier(config));
  const repository = options.repository ?? createAccountDeletionRepository(config);
  app.post('/v1/account/deletion', { preHandler: [auth, appCheck] }, async (request, reply) => {
    // Ownership comes only from verified auth — request.identityKey is the
    // ONLY value ever passed to repository.deleteForIdentity. The body's
    // expectedTargetUid is an anti-race ASSERTION the client makes against
    // its own durably-recorded deletion target: it is compared against
    // request.identityKey and REJECTED on any mismatch, but it can never
    // itself select whose data is deleted (an attacker sending someone
    // else's uid here only ever gets rejected, never gains authorization).
    // This closes a window where the client verified target==currentUser
    // before this async request began, but the LIVE Firebase identity
    // (and therefore the token this request actually authenticates as)
    // changed to a different uid before the request's headers were built.
    if (!request.identityKey) return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
    const body = request.body as { expectedTargetUid?: unknown } | undefined;
    const expectedTargetUid = typeof body?.expectedTargetUid === 'string' ? body.expectedTargetUid.trim() : '';
    if (!expectedTargetUid) return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
    // request.identityKey is a HASH of the verified subject (see
    // auth/identity.ts) — re-derive the same hash from the client-
    // asserted raw uid rather than comparing raw-vs-hashed values.
    if (identityKeyFromSubject(expectedTargetUid) !== request.identityKey) {
      return reply.code(409).send(errorEnvelope(ErrorCode.unauthorized));
    }
    try {
      return reply.code(202).send(successEnvelope(await repository.deleteForIdentity(request.identityKey)));
    } catch {
      return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
    }
  });
}
