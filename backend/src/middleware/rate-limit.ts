import type { FastifyReply, FastifyRequest } from 'fastify';
import { ErrorCode, errorEnvelope } from '../errors.js';

/** In-memory sliding window. Single instance only — not distributed. */
export function createIdentityRateLimit(max: number, windowMs: number) {
  const hits = new Map<string, number[]>();

  return async function rateLimitHook(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<void> {
    const key = request.identityKey;
    if (!key) {
      await reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
      return;
    }
    const now = Date.now();
    const recent = (hits.get(key) ?? []).filter((at) => now - at < windowMs);
    if (recent.length >= max) {
      await reply.code(429).send(errorEnvelope(ErrorCode.rateLimited));
      return;
    }
    recent.push(now);
    hits.set(key, recent);
  };
}
