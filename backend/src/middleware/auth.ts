import type { FastifyReply, FastifyRequest } from 'fastify';
import type { AuthenticationService } from '../auth/types.js';
import { ErrorCode, errorEnvelope } from '../errors.js';

export function requireAuth(auth: AuthenticationService) {
  return async function authHook(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<void> {
    const result = await auth.authenticate(
      request.headers.authorization,
      request.ip,
    );
    if (!result.ok) {
      await reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
      return;
    }
    request.authSubject = result.identity.subject;
    request.identityKey = result.identity.identityKey;
  };
}
