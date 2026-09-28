// Dream final feature audit §7 — the exact request the Flutter client sends
// (OpenAiPaidRequests.dream: client model hint, `or-dream-<id>:ds-<digest>`
// Idempotency-Key, payload incl. language) reaches the provider as the
// frozen Astra body, returns all five sections, and replays on retry.
// Fake provider only — never the network.
import { describe, expect, it } from 'vitest';
import {
  FirestoreResponseReplayRepository,
  type ReplayClaim,
  type ReplayEntry,
  type ResponseReplayRepository,
} from '../src/middleware/response-replay-repository.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import type { OpenAiFetch } from '../src/types.js';
import { ASTRA, passRaw, trFear } from './dream-phase4c3-support.js';
import { authHeader, jsonResponse, testApp, testConfig } from './helpers.js';

class SpyReplay implements ResponseReplayRepository {
  readonly inner = new FirestoreResponseReplayRepository(new MemoryDocumentStore());
  readonly keys: string[] = [];
  claim(identity: string, key: string): Promise<ReplayClaim> {
    this.keys.push(key);
    return this.inner.claim(identity, key);
  }
  complete(identity: string, key: string, attemptId: string, entry: Omit<ReplayEntry, 'expiresAtMs'>) {
    return this.inner.complete(identity, key, attemptId, entry);
  }
}

const ATTEMPT = 'or-dream-0123456789abcdef0123456789abcdef';
const CLIENT_DIGEST = 'a1b2c3d4e5f60718293a4b5c6d7e8f90';
const clientKey = (attempt = ATTEMPT) => `${attempt}:ds-${CLIENT_DIGEST}`;

/** `AiProxyRequest.toJson()` for Dream — `model` is omitted when blank. */
function clientBody(hint: string | undefined) {
  const { narrative, symbols, emotions, language } = trFear.payload as Record<string, unknown>;
  return {
    operation: 'dream_analysis',
    ...(hint ? { model: hint } : {}),
    payload: { narrative, symbols: symbols ?? [], emotions: emotions ?? [], language: language ?? 'tr' },
  };
}

async function send(key: string, repo: SpyReplay, hint: string | undefined = 'gpt-4o') {
  const bodies: Array<Record<string, unknown>> = [];
  const fetch: OpenAiFetch = async (_, init) => {
    bodies.push(JSON.parse(String(init?.body)));
    return jsonResponse({ choices: [{ message: { content: passRaw } }] });
  };
  const app = await testApp(testConfig(ASTRA), fetch, { responseReplayRepository: repo });
  const res = await app.inject({
    method: 'POST',
    url: '/v1/ai/complete',
    headers: { ...authHeader(), 'idempotency-key': key },
    payload: clientBody(hint),
  });
  await app.close();
  return { status: res.statusCode, json: res.json(), bodies };
}

describe('Dream final audit — Flutter-shaped request through the route', () => {
  for (const hint of ['gpt-4o', 'gpt-4o-mini', undefined]) {
    it(`hint ${hint ?? '(none)'} → one frozen Astra call`, async () => {
      const run = await send(clientKey(), new SpyReplay(), hint);
      expect(run.status).toBe(200);
      expect(run.bodies).toHaveLength(1);
      const body = run.bodies[0]!;
      expect(body).toMatchObject({
        model: 'gpt-6-astra',
        reasoning_effort: 'medium',
        response_format: { type: 'json_object' },
      });
      expect(body).not.toHaveProperty('temperature');
    });
  }

  it('returns every required section as non-empty prose', async () => {
    const run = await send(clientKey(), new SpyReplay());
    expect(run.json.success).toBe(true);
    for (const field of ['summary', 'emotionalTheme', 'interpretation', 'dailyLifeReflection', 'conclusion']) {
      expect(typeof run.json.data[field]).toBe('string');
      expect(String(run.json.data[field]).trim().length).toBeGreaterThan(0);
    }
  });

  it('the client key lands in the 4c3-astra replay slot; a retry replays with no call', async () => {
    const repo = new SpyReplay();
    const first = await send(clientKey(), repo);
    expect(repo.keys[0]).toMatch(new RegExp(`^${clientKey()}\\|dream-sem:4c3-astra:[0-9a-f]{32}$`));
    for (const hint of ['gpt-4o', undefined]) {
      const retry = await send(clientKey(), repo, hint);
      expect(retry.bodies).toHaveLength(0);
      expect(retry.json).toEqual(first.json);
    }
  });

  it('a new attempt id is a new provider call', async () => {
    const repo = new SpyReplay();
    await send(clientKey(), repo);
    const other = await send(clientKey('or-dream-ffffffffffffffffffffffffffffffff'), repo);
    expect(other.bodies).toHaveLength(1);
  });
});
