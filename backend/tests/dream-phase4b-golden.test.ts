import { beforeEach, describe, expect, it } from 'vitest';
import { dreamAcceptanceFailure } from '../src/ai/dream-acceptance.js';
import { parseDreamData } from '../src/ai/parse-provider.js';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import { acceptanceInput, goldenPayload, goldens, serveDream } from './dream-phase4b-support.js';

describe('Dream Phase 4B — premium golden fixtures', () => {
  beforeEach(() => readingStageStore.clear());

  it('covers at least three fixtures per language', () => {
    for (const lang of ['tr', 'en', 'ru']) {
      expect(goldens.filter((g) => g.language === lang).length).toBeGreaterThanOrEqual(3);
    }
  });

  it.each(goldens.map((g) => [g.id, g] as const))('%s passes every acceptance layer', (_, g) => {
    expect(parseDreamData(JSON.stringify(g.data))).toEqual(g.data);
    expect(dreamAcceptanceFailure(g.data, acceptanceInput(g))).toBeNull();
  });

  it.each(goldens.map((g) => [g.id, g] as const))('%s is served in one provider call', async (id, g) => {
    const res = await serveDream(g.data, goldenPayload(g), `or-dream-4b-golden-${id}`);
    expect(res.calls).toBe(1);
    expect(res.json.success).toBe(true);
    expect(res.json.data).toEqual(g.data);
  });
});
