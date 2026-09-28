// Dream Phase 4C.1 — the corrected gates end to end through the route, with a
// scripted provider (bodies from the frozen live artifact, read-only), and
// the 4c1 writer revision in the replay slot.
import { describe, expect, it } from 'vitest';
import { DREAM_WRITER_REVISION, dreamReplayKey, dreamRequestFingerprint } from '../src/ai/dream-request-identity.js';
import type { DreamData } from '../src/ai/parse-provider.js';
import {
  FirestoreResponseReplayRepository,
  type ReplayClaim,
  type ReplayEntry,
  type ResponseReplayRepository,
} from '../src/middleware/response-replay-repository.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { serveDream } from './dream-phase4b-support.js';
import { frozen, frozenPayload } from './dream-phase4c1-support.js';

const rejected = { success: false, error: { code: 'invalid_response' } };
const body = (id: string) => frozen(id).stages.parsed;
const payload = (id: string) => frozenPayload(frozen(id).caseId);

const mixed: DreamData = {
  ...body('en-mixed-emotion'),
  dailyLifeReflection:
    'The laughter and the tears at the train station may stay with you today as one moment that holds both relief and heaviness.',
};

type Case = [label: string, id: string, reply: DreamData];

const served: Case[] = [
  ['truthful history appositive', 'en-history', body('en-history')],
  ['truthful TR negated fear', 'tr-negated-fear', body('tr-negated-fear')],
  ['compressed summary', 'en-mixed-emotion', mixed],
];

const refused: Case[] = [
  ['red-history attribute', 'en-history', {
    ...body('en-history'),
    interpretation: body('en-history').interpretation.replace('The sea, a recurring', 'The red sea, a recurring'),
  }],
  ['actual TR fear contradiction', 'tr-negated-fear', { ...body('tr-negated-fear'), emotionalTheme: 'Yoğun bir korku vardı; merak geri plandaydı.' }],
  ['invented symbol also in prose', 'tr-negated-fear', {
    ...body('tr-negated-fear'),
    symbols: [...body('tr-negated-fear').symbols, 'Yılan'],
    interpretation: `${body('tr-negated-fear').interpretation} Yılan da ağaçların arasında bekliyordu.`,
  }],
  ['verbatim recap', 'en-mixed-emotion', { ...mixed, summary: 'You were at a train station saying goodbye to an old friend you had not seen in years.' }],
];

describe('Dream Phase 4C.1 — route', () => {
  served.forEach(([label, id, reply], i) => {
    it(`${label} → success, one call`, async () => {
      const { json, calls } = await serveDream(reply, payload(id), `4c1-route-ok-${String(i).padStart(4, '0')}`);
      expect(calls).toBe(1);
      expect(json.success).toBe(true);
      expect(json.data.summary).toBe(reply.summary);
    });
  });

  refused.forEach(([label, id, reply], i) => {
    it(`${label} → invalid_response, one call, no reason`, async () => {
      const { json, calls } = await serveDream(reply, payload(id), `4c1-route-red-${String(i).padStart(4, '0')}`);
      expect(calls).toBe(1);
      expect(json).toEqual(rejected);
    });
  });

  it('unsupported provider symbol is filtered and never leaves the server', async () => {
    const reply = { ...body('tr-negated-fear'), symbols: [...body('tr-negated-fear').symbols, 'Yılan'] };
    const { json, raw, calls } = await serveRaw(reply, payload('tr-negated-fear'), '4c1-route-symbol-0001');
    expect(calls).toBe(1);
    expect(json.success).toBe(true);
    expect(json.data.symbols).toEqual(['Orman', 'Ayak sesleri', 'Fener']);
    expect(raw).not.toContain('Yılan');
  });
});

async function serveRaw(reply: DreamData, p: Record<string, unknown>, key: string) {
  const { json, calls } = await serveDream(reply, p, key);
  return { json, raw: JSON.stringify(json), calls };
}

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

// The revision itself moved to '4c3-astra' in Phase 4C.3 (pinned there).
describe('Dream Phase 4C.1 — writer revision bump', () => {
  it('bumps only the replay slot; the semantic / billing fingerprint is unchanged', () => {
    expect(DREAM_WRITER_REVISION).not.toBe('4b');
    const fp = dreamRequestFingerprint({ payload: { narrative: 'a red door' }, language: 'en' });
    expect(fp).toBe('dream:v2:3d2e95d2851234367b93574161fdcf6522cc4b24b6f2c71cd6d51fd0fc0fdfc7');
    expect(dreamReplayKey('k', fp)).toMatch(new RegExp(`^k\\|dream-sem:${DREAM_WRITER_REVISION}:[0-9a-f]{32}$`));
  });

  it('never replays a 4b body; an exact 4c1 retry replays without a second call', async () => {
    const id = 'tr-negated-fear';
    const repo = new SpyReplay();
    const deps = { responseReplayRepository: repo };
    await serveDream(body(id), payload(id), '4c1-replay-probe-01', deps);
    const { identity, key } = repo.claims[0]!;
    const digest = key.split(':').pop()!;

    const idem = '4c1-replay-target-1';
    const legacyKey = `${idem}|dream-sem:4b:${digest}`;
    const seeded = await repo.inner.claim(identity, legacyKey);
    if (seeded.kind !== 'producer') throw new Error('seed failed');
    const stale = { success: true, data: { ...body(id), interpretation: 'pre-4c1 stale body' } };
    await repo.inner.complete(identity, legacyKey, seeded.attemptId, { status: 200, body: stale, contentType: 'application/json' });

    const first = await serveDream(body(id), payload(id), idem, deps);
    expect(first.calls).toBe(1);
    expect(first.json.data.interpretation).toBe(body(id).interpretation);
    const retry = await serveDream(body(id), payload(id), idem, deps);
    expect(retry.calls).toBe(0);
    expect(retry.json).toEqual(first.json);
  });
});
