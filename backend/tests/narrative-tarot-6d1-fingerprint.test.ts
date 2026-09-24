/** Phase 6D.1 — full semantic Narrative fingerprint + duplicate guard. */
import { createHash } from 'node:crypto';
import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { authHeader, testApp, testConfig } from './helpers.js';
import { validateNarrativeTarotPayload } from '../src/ai/narrative-tarot-contract.js';
import {
  canonicalJson,
  narrativeRequestFingerprint,
} from '../src/ai/narrative-tarot-canonical.js';
import { fingerprintRequest } from '../src/ai/request-fingerprint.js';
import type { ValidatedRequest } from '../src/ai/validate-request.js';

const fixture = JSON.parse(
  readFileSync(
    resolve(process.cwd(), '../test/fixtures/tarot_narrative_prompt_v1.json'),
    'utf8',
  ),
) as { scenarios: { id: string; modelInput: Record<string, unknown> }[] };

function validatedFrom(id: string) {
  const s = fixture.scenarios.find((x) => x.id === id)!;
  const language = s.modelInput.languageCode;
  return validateNarrativeTarotPayload({
    mode: 'narrative_v2',
    contractVersion: 1,
    language,
    narrative: structuredClone(s.modelInput),
  });
}

describe('6D.1 Narrative semantic fingerprint', () => {
  it('hashes full validated semantics with sorted keys; privacy-safe', () => {
    const a = validatedFrom('classical_three_en_decision');
    const fp = narrativeRequestFingerprint(a);
    expect(fp.startsWith('tarot-narrative:')).toBe(true);
    expect(fp.length).toBe('tarot-narrative:'.length + 64);
    expect(fp).toBe(fingerprintRequest(a as ValidatedRequest));

    const q = 'SECRET_QUESTION_6D1';
    const withQ = structuredClone(a.narrative);
    (withQ.question as { text: string }).text = q;
    const fpQ = narrativeRequestFingerprint(
      validateNarrativeTarotPayload({
        mode: 'narrative_v2',
        contractVersion: 1,
        language: a.language,
        narrative: withQ,
      }),
    );
    expect(fpQ).not.toContain(q);
    expect(fpQ).not.toBe(fp);

    const enriched = validatedFrom('enriched_phase4_recurrence_memory');
    const m = 'SECRET_MEMORY_6D1';
    const withM = structuredClone(enriched.narrative);
    const entries = (withM.memory as { entries: { contentForModel: string }[] })
      .entries;
    entries[0].contentForModel = m;
    const fpM = narrativeRequestFingerprint(
      validateNarrativeTarotPayload({
        mode: 'narrative_v2',
        contractVersion: 1,
        language: enriched.language,
        narrative: withM,
      }),
    );
    expect(fpM).not.toContain(m);
    expect(fpM).not.toBe(narrativeRequestFingerprint(enriched));
  });

  it('key order does not change fingerprint; array order matters', () => {
    const base = validatedFrom('classical_single_en_open');
    const preimageA = {
      mode: base.mode,
      contractVersion: base.contractVersion,
      language: base.language,
      narrative: base.narrative,
    };
    const shuffled = JSON.parse(
      JSON.stringify(preimageA, (_k, v) => {
        if (v && typeof v === 'object' && !Array.isArray(v)) {
          const entries = Object.entries(v as object).reverse();
          return Object.fromEntries(entries);
        }
        return v;
      }),
    );
    expect(canonicalJson(preimageA)).toBe(canonicalJson(shuffled));
    const fp1 = createHash('sha256')
      .update(canonicalJson(preimageA), 'utf8')
      .digest('hex');
    const fp2 = createHash('sha256')
      .update(canonicalJson(shuffled), 'utf8')
      .digest('hex');
    expect(fp1).toBe(fp2);
    expect(narrativeRequestFingerprint(base)).toBe(
      narrativeRequestFingerprint(base),
    );
  });

  it('semantic mutations change fingerprint', () => {
    const base = validatedFrom('classical_three_en_decision');
    const fp0 = narrativeRequestFingerprint(base);

    const cases: Array<(n: Record<string, unknown>) => void> = [
      (n) => {
        (n.question as { text: string }).text = 'Choice B?';
      },
      (n) => {
        (n.question as { kind: string }).kind = 'guidance';
      },
      (n) => {
        (n.question as { topic: string }).topic = 'career';
      },
      (n) => {
        (n.cards as { isReversed: boolean }[])[0].isReversed = true;
      },
      (n) => {
        (n.cards as { coreMeaning: string }[])[0].coreMeaning =
          'Different meaning for fingerprint.';
      },
      (n) => {
        const r = (n.relationships as { kind: string; strength: number }[])[0];
        if (r) r.strength = 0.11;
      },
    ];

    for (const mutate of cases) {
      const clone = structuredClone(base.narrative);
      mutate(clone);
      const v = validateNarrativeTarotPayload({
        mode: 'narrative_v2',
        contractVersion: 1,
        language: base.language,
        narrative: clone,
      });
      expect(narrativeRequestFingerprint(v)).not.toBe(fp0);
    }
  });

  it('legacy tarot fingerprint unchanged shape', () => {
    const legacy = {
      operation: 'tarot_reading' as const,
      mode: 'legacy' as const,
      language: 'tr' as const,
      cards: [
        {
          name: 'The Fool',
          positionLabel: 'Past',
          reversed: false,
          meaning: 'x',
          keywords: ['a'],
        },
      ],
      spreadLabel: 'Three Card',
      userQuestion: 'Work?',
    };
    expect(fingerprintRequest(legacy)).toBe(
      'tarot:the fool|three card|work?',
    );
    expect(fingerprintRequest(legacy)).toBe(fingerprintRequest(legacy));
  });

  it('different questions are not duplicate-guarded; exact repeat is', async () => {
    const three = fixture.scenarios.find(
      (s) => s.id === 'classical_three_en_decision',
    )!;
    const providerOk = async () =>
      new Response(
        JSON.stringify({
          choices: [
            {
              message: {
                content: JSON.stringify({
                  contractVersion: 1,
                  languageCode: 'en',
                  summary: 'A calm reflective note about presence and choice xx',
                  cardReadings: (
                    three.modelInput.cards as {
                      canonicalCardId: string;
                      positionKey: string;
                    }[]
                  ).map((c) => ({
                    cardId: c.canonicalCardId,
                    positionKey: c.positionKey,
                    text: 'A calm reflective note about presence and choice.',
                  })),
                  synthesis: 'A calm reflective note about presence and choice.',
                  relationshipInsights: [],
                  recurringCardInsights: [],
                  recurringThemeInsights: [],
                  memoryInsights: [],
                  lifeAreas: [],
                  advice: 'A calm reflective note about presence and choice.',
                  reflectionPrompt: null,
                  dailyFocus: null,
                  closingMessage:
                    'A calm reflective note about presence and choice.',
                }),
              },
            },
          ],
        }),
        { status: 200, headers: { 'content-type': 'application/json' } },
      );

    const app = await testApp(testConfig(), providerOk);
    const bodyA = {
      operation: 'tarot_reading',
      payload: {
        mode: 'narrative_v2',
        contractVersion: 1,
        language: 'en',
        narrative: {
          ...structuredClone(three.modelInput),
          languageCode: 'en',
          question: {
            text: 'Choice A?',
            topic: 'love',
            kind: 'decision',
            hasRealQuestion: true,
          },
        },
      },
    };
    const bodyB = structuredClone(bodyA);
    (bodyB.payload.narrative.question as { text: string }).text = 'Choice B?';

    const a1 = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: bodyA,
    });
    expect(a1.json().success).toBe(true);

    const b1 = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: bodyB,
    });
    expect(b1.json().success).toBe(true);

    const a2 = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: bodyA,
    });
    expect(a2.statusCode).toBe(429);
    expect(a2.json().error.code).toBe('rate_limited');
    await app.close();
  });
});
