/**
 * Phase 6E.3 — Result Contract V2 memoryIndices + prose quality + prompt rules.
 */
import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  NARRATIVE_RESULT_CONTRACT_VERSION,
  NARRATIVE_SCHEMA_NAME,
} from '../src/ai/narrative-tarot-limits.js';
import { NARRATIVE_TAROT_RESULT_SCHEMA } from '../src/ai/narrative-tarot-result-schema.js';
import { parseNarrativeTarotResult } from '../src/ai/narrative-tarot-result.js';
import { findDeterministicFuture } from '../src/ai/narrative-tarot-prose-quality.js';
import { narrativeTarotMessages } from '../src/ai/narrative-tarot-prompts.js';
import {
  memoryIndexLegend,
  narrativeSystemRules,
  resultContractDirective,
} from '../src/ai/narrative-tarot-prompt-rules.js';
import { ProxyError } from '../src/errors.js';

const resultsPath = resolve(
  process.cwd(),
  '../test/fixtures/tarot_narrative_provider_shadow_results_6e2.json',
);
const resultParserPath = resolve(
  process.cwd(),
  'src/ai/narrative-tarot-result.ts',
);

function baseNarrative(overrides: Record<string, unknown> = {}) {
  return {
    narrativeTarotVersion: 2,
    serializerVersion: 1,
    languageCode: 'en',
    question: {
      text: null,
      topic: null,
      kind: 'open',
      hasRealQuestion: false,
    },
    spread: {
      spreadId: 'classical.single',
      legacyTypeName: 'single',
      cardCount: 1,
      purposeKey: 'signal',
      positions: [
        {
          index: 0,
          positionKey: 'sign',
          role: 'signal',
          temporal: 'atemporal',
        },
      ],
      interpretationOrder: [0],
      geometryHook: 'singlePoint',
      lengthBand: 'short',
    },
    cards: [
      {
        canonicalCardId: 'major_00',
        ritualCardId: 0,
        displayName: 'The Fool',
        isReversed: false,
        positionKey: 'sign',
        positionIndex: 0,
        keywordIds: ['threshold'],
        symbolTags: ['threshold'],
        coreMeaning: 'threshold',
        light: 'open',
        shadow: 'scatter',
        tension: 'move',
        orientationExpression: 'open',
        transforms: [],
      },
    ],
    relationships: [],
    recurringCards: [],
    recurringThemes: [],
    memory: { included: false, priorReadingCount: 0, entries: [] },
    policy: {
      version: 'narrative_policy_v1',
      rules: [
        'do_not_invent_cards',
        'do_not_invent_position_roles',
        'do_not_invent_relationships',
        'do_not_invent_recurrence',
        'do_not_invent_memory_or_history',
        'no_deterministic_prophecy',
        'distinguish_evidence_from_reflective_guidance',
        'answer_in_requested_language',
        'do_not_expose_internal_identifiers',
      ],
    },
    ...overrides,
  };
}

function prose(n = 50): string {
  return `A calm reflective note about presence and choice ${'x'.repeat(Math.max(0, n - 40))}`;
}

function validResult(narrative: ReturnType<typeof baseNarrative>) {
  const cards = narrative.cards as { canonicalCardId: string; positionKey: string }[];
  const memory = narrative.memory as { included: boolean; entries: unknown[] };
  return {
    contractVersion: 2,
    languageCode: narrative.languageCode,
    summary: prose(80),
    cardReadings: cards.map((c) => ({
      cardId: c.canonicalCardId,
      positionKey: c.positionKey,
      text: prose(60),
    })),
    synthesis: prose(90),
    relationshipInsights: [],
    recurringCardInsights: [],
    recurringThemeInsights: [],
    memoryInsights:
      memory.included && memory.entries.length > 0
        ? [{ memoryIndices: [0], text: prose(50) }]
        : [],
    lifeAreas: [],
    advice: prose(50),
    reflectionPrompt: null,
    dailyFocus: null,
    closingMessage: prose(50),
  };
}

describe('6E.3 Result Contract V2', () => {
  it('schema name and version are v2', () => {
    expect(NARRATIVE_RESULT_CONTRACT_VERSION).toBe(2);
    expect(NARRATIVE_SCHEMA_NAME).toBe('oracly_tarot_narrative_v2');
    expect(NARRATIVE_TAROT_RESULT_SCHEMA.properties.contractVersion.const).toBe(2);
    const mem = NARRATIVE_TAROT_RESULT_SCHEMA.properties.memoryInsights.items;
    expect(mem.required).toEqual(['memoryIndices', 'text']);
    expect(mem.properties).not.toHaveProperty('memoryIndex');
  });

  it('accepts memoryIndices [0] and [0,1]; rejects v1 memoryIndex and reuse', () => {
    const narrative = baseNarrative({
      memory: {
        included: true,
        priorReadingCount: 2,
        entries: [
          {
            kind: 'memorySummary',
            contentForModel: 'coffee note',
            sourceType: 'coffee',
            confidence: 0.8,
            epistemic: 'interpretation',
            occurredAtUtc: '2026-09-21T12:00:00.000Z',
          },
          {
            kind: 'memorySummary',
            contentForModel: 'dream note',
            sourceType: 'dream',
            confidence: 0.8,
            epistemic: 'interpretation',
            occurredAtUtc: '2026-09-19T12:00:00.000Z',
          },
        ],
      },
    });
    const combined = validResult(narrative);
    combined.memoryInsights = [
      { memoryIndices: [0, 1], text: prose(50) },
    ];
    expect(parseNarrativeTarotResult(JSON.stringify(combined), narrative as never).memoryInsights[0]?.memoryIndices).toEqual([0, 1]);

    const split = validResult(narrative);
    split.memoryInsights = [
      { memoryIndices: [0], text: prose(50) },
      { memoryIndices: [1], text: prose(50) },
    ];
    expect(parseNarrativeTarotResult(JSON.stringify(split), narrative as never).memoryInsights).toHaveLength(2);

    const v1 = validResult(narrative) as Record<string, unknown>;
    v1.memoryInsights = [{ memoryIndex: 0, text: prose(50) }];
    expect(() => parseNarrativeTarotResult(JSON.stringify(v1), narrative as never)).toThrow();

    const reuse = validResult(narrative);
    reuse.memoryInsights = [
      { memoryIndices: [0, 1], text: prose(50) },
      { memoryIndices: [1], text: prose(50) },
    ];
    expect(() => parseNarrativeTarotResult(JSON.stringify(reuse), narrative as never)).toThrow();

    const unsorted = validResult(narrative);
    unsorted.memoryInsights = [{ memoryIndices: [1, 0], text: prose(50) }];
    expect(() => parseNarrativeTarotResult(JSON.stringify(unsorted), narrative as never)).toThrow();
  });

  it('rejects historical Call #4 certainty; accepts conditional rewrite', () => {
    const captured = JSON.parse(readFileSync(resultsPath, 'utf8')) as {
      calls: { callNumber: number; structuredResult: { synthesis: string; relationshipInsights: { text: string }[] } }[];
    };
    const call4 = captured.calls.find((c) => c.callNumber === 4)!;
    const text = [
      call4.structuredResult.synthesis,
      ...call4.structuredResult.relationshipInsights.map((r) => r.text),
    ].join('\n');
    expect(findDeterministicFuture(text, 'en')?.code).toBe('deterministicFuture');

    const conditional =
      'The future may point toward a return to balance through honest assessment. Resolving present discord could open a fairer path.';
    expect(findDeterministicFuture(conditional, 'en')).toBeNull();
  });

  it('6E.3.1 — prose-quality stage uses pure detector; no broad catch', () => {
    const src = readFileSync(resultParserPath, 'utf8');
    expect(src).toMatch(/findDeterministicFuture\s*\(/);
    expect(src).toMatch(/narrativeVisibleProse\s*\(/);
    expect(src).not.toMatch(/assertNarrativeProseQuality/);
    const stageStart = src.indexOf('assertTotalChars(result)');
    const stageEnd = src.indexOf('return result;', stageStart);
    expect(stageStart).toBeGreaterThan(-1);
    expect(stageEnd).toBeGreaterThan(stageStart);
    const stage = src.slice(stageStart, stageEnd);
    expect(stage).not.toMatch(/catch\s*(\(|\{)/);
    expect(stage).not.toMatch(/try\s*\{/);
  });

  it('6E.3.1 — deterministicFuture parse → invalid_response; unexpected errors not swallowed', () => {
    const narrative = baseNarrative();
    const prophetic = validResult(narrative);
    prophetic.synthesis =
      'The future promises a return to balance; resolving present discord will lead to fairer outcomes.';
    try {
      parseNarrativeTarotResult(JSON.stringify(prophetic), narrative as never);
      expect(false).toBe(true);
    } catch (e) {
      expect(e).toBeInstanceOf(ProxyError);
      expect((e as ProxyError).code).toBe('invalid_response');
    }

    const ok = validResult(narrative);
    ok.synthesis =
      'The future may point toward a return to balance through honest assessment.';
    expect(
      parseNarrativeTarotResult(JSON.stringify(ok), narrative as never).synthesis,
    ).toContain('may point toward');
  });

  it('prompt rules cover future modality, mind-reading, memoryIndices, sections', () => {
    const rules = narrativeSystemRules().join('\n');
    expect(rules).toMatch(/possibility|trajectory|invitation/i);
    expect(rules).toMatch(/partner/i);
    expect(rules).toMatch(/mental state/i);
    expect(rules).toMatch(/lifeAreas are optional/i);
    expect(rules).toMatch(/Do not repeat/i);
    expect(rules).toMatch(/natively/i);
    expect(rules).toMatch(/TR:/);
    expect(rules).toMatch(/RU:/);
    expect(resultContractDirective()).toMatch(/Version 2/);
    expect(resultContractDirective()).toMatch(/memoryIndices/);

    const withMem = baseNarrative({
      memory: {
        included: true,
        priorReadingCount: 2,
        entries: [{ kind: 'memorySummary', contentForModel: 'a' }, { kind: 'memorySummary', contentForModel: 'b' }],
      },
    });
    const legend = memoryIndexLegend(withMem as never);
    expect(legend).toContain('Memory 0');
    expect(legend).toContain('Memory 1');

    const msgs = narrativeTarotMessages(withMem as never, 'en');
    const joined = msgs.map((m) => m.content).join('\n');
    expect(joined).toContain('Version 2');
    expect(joined).toContain('Memory 0');
    expect(joined).toMatch(/may \/ could/i);
  });
});
