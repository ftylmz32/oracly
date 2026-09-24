/** Phase 6D.1 — deep Narrative inbound contract + frozen 6C fixture gate. */
import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { authHeader, testApp, testConfig } from './helpers.js';
import { validateNarrativeTarotPayload } from '../src/ai/narrative-tarot-contract.js';
import { NARRATIVE_LIMITS } from '../src/ai/narrative-tarot-limits.js';
import { ProxyError } from '../src/errors.js';

const fixture = JSON.parse(
  readFileSync(
    resolve(process.cwd(), '../test/fixtures/tarot_narrative_prompt_v1.json'),
    'utf8',
  ),
) as { scenarios: { id: string; modelInput: Record<string, unknown> }[] };

function wrap(modelInput: Record<string, unknown>) {
  const language = modelInput.languageCode;
  return {
    mode: 'narrative_v2',
    contractVersion: 1,
    language,
    narrative: structuredClone(modelInput),
  };
}

function expectInvalid(payload: Record<string, unknown>) {
  try {
    validateNarrativeTarotPayload(payload);
    throw new Error('expected invalid_request');
  } catch (e) {
    expect(e).toBeInstanceOf(ProxyError);
    expect((e as ProxyError).code).toBe('invalid_request');
  }
}

describe('6D.1 Narrative inbound firewall', () => {
  it('accepts all 8 frozen Phase 6C serializer scenarios', () => {
    expect(fixture.scenarios).toHaveLength(8);
    const sizes: number[] = [];
    for (const s of fixture.scenarios) {
      const validated = validateNarrativeTarotPayload(wrap(s.modelInput));
      const n = JSON.stringify(validated.narrative).length;
      sizes.push(n);
      expect(n).toBeLessThanOrEqual(NARRATIVE_LIMITS.maxNarrativeJsonChars);
    }
    expect(Math.max(...sizes)).toBeGreaterThan(0);
    expect(Math.min(...sizes)).toBeGreaterThan(0);
    // expose for report via console (tests still assert)
    console.log(
      `FROZEN_SIZES max=${Math.max(...sizes)} min=${Math.min(...sizes)}`,
    );
  });

  it('rejects unknown enums / wrong types / oversized fields', () => {
    const base = wrap(fixture.scenarios[0].modelInput);
    const n = base.narrative as Record<string, unknown>;

    expectInvalid({
      ...base,
      narrative: {
        ...n,
        question: { ...(n.question as object), kind: 'prediction' },
      },
    });

    expectInvalid({
      ...base,
      narrative: {
        ...n,
        spread: { ...(n.spread as object), geometryHook: 'fiveDecision' },
      },
    });

    const cards = structuredClone(n.cards) as Record<string, unknown>[];
    cards[0].coreMeaning = { bad: true };
    expectInvalid({ ...base, narrative: { ...n, cards } });

    const cards2 = structuredClone(n.cards) as Record<string, unknown>[];
    cards2[0].coreMeaning = 'x'.repeat(1001);
    expectInvalid({ ...base, narrative: { ...n, cards: cards2 } });

    const cards3 = structuredClone(n.cards) as Record<string, unknown>[];
    cards3[0].transforms = ['madeUpTransform'];
    expectInvalid({ ...base, narrative: { ...n, cards: cards3 } });

    const cards4 = structuredClone(n.cards) as Record<string, unknown>[];
    cards4[0].keywordIds = [123];
    expectInvalid({ ...base, narrative: { ...n, cards: cards4 } });
  });

  it('rejects bad relationship / orientation / memory / total size', () => {
    const three = fixture.scenarios.find(
      (s) => s.id === 'classical_three_en_decision',
    )!;
    const base = wrap(three.modelInput);
    const n = base.narrative as Record<string, unknown>;
    const rels = structuredClone(n.relationships) as Record<string, unknown>[];
    if (rels[0]) {
      rels[0].kind = 'invented';
      expectInvalid({ ...base, narrative: { ...n, relationships: rels } });
    }

    const enriched = fixture.scenarios.find(
      (s) => s.id === 'enriched_phase4_recurrence_memory',
    )!;
    const eBase = wrap(enriched.modelInput);
    const en = eBase.narrative as Record<string, unknown>;
    const rec = structuredClone(en.recurringCards) as Record<string, unknown>[];
    const occ = (rec[0].occurrences as Record<string, unknown>[])[0];
    occ.orientationKnown = false;
    occ.isReversed = false;
    expectInvalid({ ...eBase, narrative: { ...en, recurringCards: rec } });

    const mem = structuredClone(en.memory) as Record<string, unknown>;
    const entries = mem.entries as Record<string, unknown>[];
    entries[0].sourceType = 'internalDb';
    expectInvalid({ ...eBase, narrative: { ...en, memory: mem } });

    const huge = wrap(fixture.scenarios[0].modelInput);
    const hn = huge.narrative as Record<string, unknown>;
    const hc = structuredClone(hn.cards) as Record<string, unknown>[];
    hc[0].coreMeaning = 'x'.repeat(50_000);
    expectInvalid({ ...huge, narrative: { ...hn, cards: hc } });
  });

  it('malformed Narrative never reaches provider', async () => {
    let fetches = 0;
    const app = await testApp(testConfig(), async () => {
      fetches += 1;
      return new Response('{}', { status: 200 });
    });
    const base = wrap(fixture.scenarios[0].modelInput);
    (base.narrative as { question: { kind: string } }).question.kind =
      'prediction';
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: { operation: 'tarot_reading', payload: base },
    });
    expect(res.json().error.code).toBe('invalid_request');
    expect(fetches).toBe(0);
    await app.close();
  });
});
