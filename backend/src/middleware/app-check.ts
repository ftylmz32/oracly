import type { FastifyReply, FastifyRequest } from 'fastify';
import {
  readAppCheckHeader,
  type AppCheckVerifier,
} from '../auth/app-check.js';
import { ErrorCode, errorEnvelope } from '../errors.js';

/**
 * Additional attestation gate after Firebase Auth.
 * Expects header: X-Firebase-AppCheck
 */
export function requireAppCheck(verifier: AppCheckVerifier) {
  return async function appCheckHook(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<void> {
    request.appCheckAppId = '';
    if (verifier.mode === 'bypass') return;
    const token = readAppCheckHeader(
      request.headers as Record<string, unknown>,
    );
    const result = await verifier.verify(token);
    if (result.ok) {
      request.appCheckAppId = result.appId ?? '';
      return;
    }
    // Sanitized — do not distinguish missing vs invalid to clients.
    await reply.code(401).send(errorEnvelope(ErrorCode.appCheckRequired));
  };
}
