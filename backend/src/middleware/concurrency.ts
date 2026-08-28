import type { FastifyReply, FastifyRequest } from 'fastify';
import { ErrorCode, errorEnvelope } from '../errors.js';

export function createConcurrencyGate(maxPerIdentity: number) {
  const inflight = new Map<string, number>();

  return async function concurrencyHook(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<void> {
    const key = request.identityKey;
    if (!key) {
      await reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
      return;
    }
    const current = inflight.get(key) ?? 0;
    if (current >= maxPerIdentity) {
      await reply.code(429).send(errorEnvelope(ErrorCode.rateLimited));
      return;
    }
    inflight.set(key, current + 1);
    reply.raw.once('close', () => {
      const next = (inflight.get(key) ?? 1) - 1;
      if (next <= 0) inflight.delete(key);
      else inflight.set(key, next);
    });
  };
}
