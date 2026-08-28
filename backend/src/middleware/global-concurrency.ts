import type { FastifyReply, FastifyRequest } from 'fastify';
import { ErrorCode, errorEnvelope } from '../errors.js';

/**
 * Process-wide concurrent AI request ceiling across ALL subjects.
 * In-memory only — valid for a single backend instance.
 * Always releases the slot on finish/close (success, error, timeout).
 */
export function createGlobalConcurrencyGate(max: number) {
  let inflight = 0;

  return async function globalConcurrencyHook(
    _request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<void> {
    if (inflight >= max) {
      await reply.code(429).send(errorEnvelope(ErrorCode.rateLimited));
      return;
    }
    inflight += 1;
    let released = false;
    const release = () => {
      if (released) return;
      released = true;
      inflight = Math.max(0, inflight - 1);
    };
    reply.raw.once('finish', release);
    reply.raw.once('close', release);
  };
}

/** Test helper with peek for release assertions. */
export function createGlobalConcurrencyGateWithPeek(max: number): {
  hook: (
    request: FastifyRequest,
    reply: FastifyReply,
  ) => Promise<void>;
  peek: () => number;
} {
  let inflight = 0;
  const hook = async function globalConcurrencyHook(
    _request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<void> {
    if (inflight >= max) {
      await reply.code(429).send(errorEnvelope(ErrorCode.rateLimited));
      return;
    }
    inflight += 1;
    let released = false;
    const release = () => {
      if (released) return;
      released = true;
      inflight = Math.max(0, inflight - 1);
    };
    reply.raw.once('finish', release);
    reply.raw.once('close', release);
  };
  return { hook, peek: () => inflight };
}
