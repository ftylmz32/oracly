// Dream Phase 4C.3 — writer revision '4c3-astra': a pre-4C.3 '4c1' body is
// never replayed, an exact retry replays without a second provider call, and
// the dream:v2 semantic / billing identity is unchanged.
import { createHash } from 'node:crypto';
import { describe, expect, it } from 'vitest';
import { DREAM_WRITER_REVISION, dreamReplayKey, dreamRequestFingerprint } from '../src/ai/dream-request-identity.js';
import { fingerprintRequest } from '../src/ai/request-fingerprint.js';
import { validateAiBody } from '../src/ai/validate-request.js';
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
  readonly claims: Array<{ identity: string; key: string }> = [];
  claim(identity: string, key: string): Promise<ReplayClaim> {
    this.claims.push({ identity, key });
    return this.inner.claim(identity, key);
  }
  complete(identity: string, key: string, attemptId: string, entry: Omit<ReplayEntry, 'expiresAtMs'>) {
    return this.inner.complete(identity, key, attemptId, entry);
  }
}

async function serve(key: string, repo: SpyReplay, model: unknown = 'gpt-4o') {
  const models: unknown[] = [];
  const fetch: OpenAiFetch = async (_, init) => {
    models.push(JSON.parse(String(init?.body)).model);
    return jsonResponse({ choices: [{ message: { content: passRaw } }] });
  };
  const app = await testApp(testConfig(ASTRA), fetch, { responseReplayRepository: repo });
  const res = await app.inject({
    method: 'POST',
    url: '/v1/ai/complete',
    headers: { ...authHeader(), 'idempotency-key': key },
    payload: { operation: 'dream_analysis', payload: trFear.payload, model },
  });
  await app.close();
  return { json: res.json(), calls: models.length, models };
}

describe('Dream Phase 4C.3 — writer revision', () => {
  it("is '4c3-astra'; only the replay slot changes, the digest does not", () => {
    expect(DREAM_WRITER_REVISION).toBe('4c3-astra');
    const fp = dreamRequestFingerprint({ payload: { narrative: 'a red door' }, language: 'en' });
    const digest = createHash('sha256').update(fp).digest('hex').slice(0, 32);
    expect(dreamReplayKey('k', fp)).toBe(`k|dream-sem:4c3-astra:${digest}`);
    expect(dreamReplayKey('k', fp)).not.toBe(`k|dream-sem:4c1:${digest}`);
  });

  it('never replays a pre-4C.3 4c1 body; an exact retry replays without a second call', async () => {
    const repo = new SpyReplay();
    await serve('4c3-replay-probe-01', repo);
    const { identity, key } = repo.claims[0]!;
    const digest = key.split(':').pop()!;

    const idem = '4c3-replay-target-1';
    const legacyKey = `${idem}|dream-sem:4c1:${digest}`;
    const seeded = await repo.inner.claim(identity, legacyKey);
    if (seeded.kind !== 'producer') throw new Error('seed failed');
    const stale = { success: true, data: { summary: 'pre-4C.3 stale 4c1 body' } };
    await repo.inner.complete(identity, legacyKey, seeded.attemptId, { status: 200, body: stale, contentType: 'application/json' });

    const first = await serve(idem, repo);
    expect(first.calls).toBe(1);
    expect(first.models).toEqual(['gpt-6-astra']);
    expect(first.json.success).toBe(true);
    expect(first.json).not.toEqual(stale);

    for (const model of ['gpt-4o', 'gpt-6-sol', undefined]) {
      const retry = await serve(idem, repo, model);
      expect(retry.calls).toBe(0);
      expect(retry.json).toEqual(first.json);
    }
  });
});

describe('Dream Phase 4C.3 — billing identity unchanged', () => {
  it('dream:v2 fingerprints are pinned', () => {
    expect(dreamRequestFingerprint({ payload: { narrative: 'a red door' }, language: 'en' })).toBe(
      'dream:v2:3d2e95d2851234367b93574161fdcf6522cc4b24b6f2c71cd6d51fd0fc0fdfc7',
    );
    const rich = { narrative: 'A red door in the sea', symbols: ['Door', 'sea'], emotions: ['calm'], memorySummary: 'Water returns often.' };
    expect(dreamRequestFingerprint({ payload: rich, language: 'en' })).toBe(
      'dream:v2:c06acb1a446231612b79400b4c944abdd7b9fec98ece7ab9784ea867996258a5',
    );
  });

  it('the duplicate / billing fingerprint ignores the writer and the client model hint', () => {
    const fps = ['gpt-4o', 'gpt-6-astra', undefined].map((model) =>
      fingerprintRequest(validateAiBody({ operation: 'dream_analysis', payload: trFear.payload, model })),
    );
    expect(new Set(fps).size).toBe(1);
    expect(fps[0]).toMatch(/^dream:v2:[0-9a-f]{64}$/);
  });
});
