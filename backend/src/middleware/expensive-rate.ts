/** Stricter window for expensive ops — chat/TTS stay on identity limit. */
import type { FastifyReply, FastifyRequest } from 'fastify';
import { ErrorCode, errorEnvelope } from '../errors.js';
import { isExpensiveOperation } from '../ai/request-fingerprint.js';
import type { SharedWindowStore } from '../rate-limit/shared-window-store.js';

export function createExpensiveRateLimit(max: number, windowMs: number, shared?: SharedWindowStore) {
  const hits = new Map<string, number[]>();

  return async function rejectExpensiveBurst(
    request: FastifyRequest,
    reply: FastifyReply,
    operation: string,
  ): Promise<boolean> {
    if (!isExpensiveOperation(operation)) return false;
    const key = request.identityKey;
    if (!key) return false;
    if (shared) {
      const allowed = await shared.consume(`expensive:${operation}`, key, max, windowMs);
      if (!allowed) void reply.code(429).send(errorEnvelope(ErrorCode.rateLimited));
      return !allowed;
    }
    const now = Date.now();
    const recent = (hits.get(key) ?? []).filter((at) => now - at < windowMs);
    if (recent.length >= max) {
      void reply.code(429).send(errorEnvelope(ErrorCode.rateLimited));
      return true;
    }
    recent.push(now);
    hits.set(key, recent);
    return false;
  };
}
