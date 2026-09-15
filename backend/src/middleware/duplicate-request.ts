/** Short-window duplicate filter — same body, not a second reading. */
import type { FastifyReply, FastifyRequest } from 'fastify';
import { ErrorCode, errorEnvelope } from '../errors.js';
import type { SharedWindowStore } from '../rate-limit/shared-window-store.js';

type Hit = { at: number; fingerprint: string };

const windows: Record<string, number> = {
  chat: 1_200,
  oracle: 1_200,
  tts: 1_200,
  dream_analysis: 5_000,
  coffee_analysis: 5_000,
  palm_analysis: 5_000,
  soulmate_draw: 8_000,
  soulmate_interpretation: 1_200,
};

export function createDuplicateRequestGuard(shared?: SharedWindowStore) {
  const recent = new Map<string, Hit>();

  return async function rejectDuplicate(
    request: FastifyRequest,
    reply: FastifyReply,
    operation: string,
    fingerprint: string,
  ): Promise<boolean> {
    const key = request.identityKey;
    if (!key || !fingerprint) return false;
    const bucket = `${key}|${operation}`;
    const now = Date.now();
    const windowMs = windows[operation] ?? 2_000;
    if (shared) {
      const allowed = await shared.consume(`duplicate:${operation}`, `${key}:${fingerprint}`, 1, windowMs);
      if (!allowed) void reply.code(429).send(errorEnvelope(ErrorCode.rateLimited));
      return !allowed;
    }
    const last = recent.get(bucket);
    if (
      last &&
      last.fingerprint === fingerprint &&
      now - last.at < windowMs
    ) {
      void reply.code(429).send(errorEnvelope(ErrorCode.rateLimited));
      return true;
    }
    recent.set(bucket, { at: now, fingerprint });
    if (recent.size > 2_000) {
      for (const [id, hit] of recent) {
        if (now - hit.at > 60_000) recent.delete(id);
      }
    }
    return false;
  };
}
