/** Stricter window for expensive ops — chat/TTS stay on identity limit. */
import type { FastifyReply, FastifyRequest } from 'fastify';
import { ErrorCode, errorEnvelope } from '../errors.js';
import { isExpensiveOperation } from '../ai/request-fingerprint.js';

export function createExpensiveRateLimit(max: number, windowMs: number) {
  const hits = new Map<string, number[]>();

  return function rejectExpensiveBurst(
    request: FastifyRequest,
    reply: FastifyReply,
    operation: string,
  ): boolean {
    if (!isExpensiveOperation(operation)) return false;
    const key = request.identityKey;
    if (!key) return false;
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
