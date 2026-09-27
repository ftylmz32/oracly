import { describe, expect, it } from 'vitest';
import { DREAM_WRITER_REVISION, dreamReplayKey, dreamRequestFingerprint } from '../src/ai/dream-request-identity.js';
import {
  FirestoreResponseReplayRepository,
  type ReplayClaim,
  type ReplayEntry,
  type ResponseReplayRepository,
} from '../src/middleware/response-replay-repository.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { golden, goldenPayload, serveDream } from './dream-phase4b-support.js';

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

describe('Dream Phase 4B — writer revision in the replay slot', () => {
  it('salts only the replay key; the semantic fingerprint is unchanged', () => {
    const fp = dreamRequestFingerprint({ payload: { narrative: 'a red door' }, language: 'en' });
    expect(fp).toBe('dream:v2:3d2e95d2851234367b93574161fdcf6522cc4b24b6f2c71cd6d51fd0fc0fdfc7');
    expect(dreamReplayKey('k', fp)).toMatch(new RegExp(`^k\\|dream-sem:${DREAM_WRITER_REVISION}:[0-9a-f]{32}$`));
  });

  it('never replays a pre-4B body; an exact 4B retry replays', async () => {
    const g = golden('en-sparse-horse');
    const repo = new SpyReplay();
    const deps = { responseReplayRepository: repo };
    const probe = await serveDream(g.data, goldenPayload(g), '4b-replay-probe-01', deps);
    expect(probe.calls).toBe(1);
    const { identity, key } = repo.claims[0]!;
    const digest = key.split(':').pop()!;

    const idem = '4b-replay-target-1';
    const legacyKey = `${idem}|dream-sem:${digest}`;
    const seeded = await repo.inner.claim(identity, legacyKey);
    if (seeded.kind !== 'producer') throw new Error('seed failed');
    const stale = { success: true, data: { ...g.data, interpretation: 'pre-4B stale body' } };
    await repo.inner.complete(identity, legacyKey, seeded.attemptId, { status: 200, body: stale, contentType: 'application/json' });

    const first = await serveDream(g.data, goldenPayload(g), idem, deps);
    expect(first.calls).toBe(1);
    expect(first.json.data.interpretation).toBe(g.data.interpretation);

    const retry = await serveDream(g.data, goldenPayload(g), idem, deps);
    expect(retry.calls).toBe(0);
    expect(retry.json).toEqual(first.json);
  });
});
