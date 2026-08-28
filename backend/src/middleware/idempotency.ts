/** Paid-op idempotency — replay successful responses for the same key. */
import type { FastifyReply, FastifyRequest } from 'fastify';

type Entry = {
  at: number;
  body: unknown;
  status: number;
};

const TTL_MS = 10 * 60_000;
const MAX = 200;

export function createIdempotencyStore() {
  const cache = new Map<string, Entry>();
  const inflight = new Map<string, Promise<Entry>>();

  function sweep(now: number) {
    if (cache.size <= MAX) return;
    for (const [id, entry] of cache) {
      if (now - entry.at > TTL_MS) cache.delete(id);
    }
  }

  return {
    lookup(identity: string, key: string): Entry | null {
      const id = `${identity}|${key}`;
      const hit = cache.get(id);
      if (!hit) return null;
      if (Date.now() - hit.at > TTL_MS) {
        cache.delete(id);
        return null;
      }
      return hit;
    },

    async run(
      identity: string,
      key: string,
      action: () => Promise<{ status: number; body: unknown }>,
    ): Promise<Entry> {
      const id = `${identity}|${key}`;
      const cached = this.lookup(identity, key);
      if (cached) return cached;
      const pending = inflight.get(id);
      if (pending) return pending;
      const work = (async () => {
        const result = await action();
        const entry: Entry = {
          at: Date.now(),
          body: result.body,
          status: result.status,
        };
        if (result.status === 200) {
          cache.set(id, entry);
          sweep(entry.at);
        }
        return entry;
      })().finally(() => inflight.delete(id));
      inflight.set(id, work);
      return work;
    },

    async replyCached(
      reply: FastifyReply,
      entry: Entry,
    ): Promise<void> {
      await reply.code(entry.status).send(entry.body);
    },

    keyFrom(request: FastifyRequest): string | null {
      const header = request.headers['idempotency-key'];
      if (typeof header !== 'string') return null;
      const key = header.trim();
      if (!key || key.length > 128) return null;
      if (!/^[A-Za-z0-9._:-]+$/.test(key)) return null;
      return key;
    },
  };
}

export type IdempotencyStore = ReturnType<typeof createIdempotencyStore>;
