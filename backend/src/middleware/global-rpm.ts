import type { FastifyReply, FastifyRequest } from 'fastify';
import { ErrorCode, errorEnvelope } from '../errors.js';

/**
 * Process-wide requests-per-minute ceiling across ALL subjects.
 * In-memory only — valid for a single backend instance.
 */
export function createGlobalRpmGate(maxPerMinute: number) {
  const hits: number[] = [];
  const windowMs = 60_000;

  return async function globalRpmHook(
    _request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<void> {
    const now = Date.now();
    while (hits.length > 0 && now - hits[0]! >= windowMs) {
      hits.shift();
    }
    if (hits.length >= maxPerMinute) {
      await reply.code(429).send(errorEnvelope(ErrorCode.rateLimited));
      return;
    }
    hits.push(now);
  };
}
