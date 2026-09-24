/**
 * Phase 6E.4.1 — OpenAI Structured Outputs schema compatibility +
 * provider error observability (no network / no real provider calls).
 */
import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  NARRATIVE_LIMITS,
  NARRATIVE_SCHEMA_NAME,
} from '../src/ai/narrative-tarot-limits.js';
import { NARRATIVE_TAROT_RESULT_SCHEMA } from '../src/ai/narrative-tarot-result-schema.js';
import { parseNarrativeTarotResult } from '../src/ai/narrative-tarot-result.js';
import { validateNarrativeTarotPayload } from '../src/ai/narrative-tarot-contract.js';
import { narrativeTarotMessages } from '../src/ai/narrative-tarot-prompts.js';
import {
  buildChatCompletionBody,
  OpenAiTransport,
} from '../src/ai/openai-transport.js';
import { ErrorCode, ProxyError, errorEnvelope } from '../src/errors.js';
import { testConfig } from './helpers.js';

/** Keywords not in OpenAI Structured Outputs supported subset. */
const UNSUPPORTED_STRUCTURED_OUTPUT_KEYS = new Set([
  'uniqueItems',
  'contains',
  'minContains',
  'maxContains',
  'unevaluatedItems',
  'allOf',
  'not',
  'dependentRequired',
  'dependentSchemas',
  'if',
  'then',
  'else',
]);

function collectUnsupportedKeys(
  node: unknown,
  path = '$',
  hits: string[] = [],
): string[] {
  if (Array.isArray(node)) {
    node.forEach((item, i) => collectUnsupportedKeys(item, `${path}[${i}]`, hits));
    return hits;
  }
  if (node && typeof node === 'object') {
    for (const [k, v] of Object.entries(node as Record<string, unknown>)) {
      if (UNSUPPORTED_STRUCTURED_OUTPUT_KEYS.has(k)) {
        hits.push(`${path}.${k}`);
      }
      collectUnsupportedKeys(v, `${path}.${k}`, hits);
    }
  }
  return hits;
}

function prose(n = 50): string {
  return `A calm reflective note about presence and choice ${'x'.repeat(Math.max(0, n - 40))}`;
}

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

function validResult(narrative: ReturnType<typeof baseNarrative>) {
  const cards = narrative.cards as {
    canonicalCardId: string;
    positionKey: string;
  }[];
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
    memoryInsights: [{ memoryIndices: [0, 1], text: prose(50) }],
    lifeAreas: [],
    advice: prose(50),
    reflectionPrompt: null,
    dailyFocus: null,
    closingMessage: prose(50),
  };
}

describe('6E.4.1 provider schema compatibility', () => {
  it('Narrative result schema has no unsupported Structured Outputs keywords', () => {
    const hits = collectUnsupportedKeys(NARRATIVE_TAROT_RESULT_SCHEMA);
    expect(hits).toEqual([]);
  });

  it('memoryIndices provider shape is supported and omits uniqueItems', () => {
    const mem = NARRATIVE_TAROT_RESULT_SCHEMA.properties.memoryInsights.items
      .properties.memoryIndices as {
      type: string;
      minItems: number;
      maxItems: number;
      items: { type: string; minimum: number };
      uniqueItems?: boolean;
    };
    expect(mem.type).toBe('array');
    expect(mem.minItems).toBe(1);
    expect(mem.maxItems).toBe(NARRATIVE_LIMITS.maxMemoryEntries);
    expect(mem.items.type).toBe('integer');
    expect(mem.items.minimum).toBe(0);
    expect(mem).not.toHaveProperty('uniqueItems');
  });

  it('backend still rejects duplicate / unsorted / globally reused memoryIndices', () => {
    const narrative = baseNarrative();
    const dup = validResult(narrative);
    dup.memoryInsights = [{ memoryIndices: [0, 0], text: prose(50) }];
    expect(() =>
      parseNarrativeTarotResult(JSON.stringify(dup), narrative as never),
    ).toThrow(ProxyError);

    const unsorted = validResult(narrative);
    unsorted.memoryInsights = [{ memoryIndices: [1, 0], text: prose(50) }];
    expect(() =>
      parseNarrativeTarotResult(JSON.stringify(unsorted), narrative as never),
    ).toThrow(ProxyError);

    const reuse = validResult(narrative);
    reuse.memoryInsights = [
      { memoryIndices: [0, 1], text: prose(50) },
      { memoryIndices: [1], text: prose(50) },
    ];
    expect(() =>
      parseNarrativeTarotResult(JSON.stringify(reuse), narrative as never),
    ).toThrow(ProxyError);

    const ok = validResult(narrative);
    expect(
      parseNarrativeTarotResult(JSON.stringify(ok), narrative as never)
        .memoryInsights[0]?.memoryIndices,
    ).toEqual([0, 1]);
  });

  it('exact outbound chat body attaches oracly_tarot_narrative_v2 without unsupported keys', () => {
    const payloads = JSON.parse(
      readFileSync(
        resolve(
          process.cwd(),
          '../test/fixtures/tarot_narrative_provider_shadow_payloads_6e4_v2.json',
        ),
        'utf8',
      ),
    ) as {
      entries: Array<{ wirePayload: Record<string, unknown> }>;
    };
    expect(payloads.entries).toHaveLength(6);
    for (const e of payloads.entries) {
      const validated = validateNarrativeTarotPayload(e.wirePayload);
      const messages = narrativeTarotMessages(
        validated.narrative,
        validated.language,
      );
      const body = buildChatCompletionBody({
        model: 'gpt-4o',
        messages,
        temperature: 0.55,
        jsonSchema: {
          name: NARRATIVE_SCHEMA_NAME,
          schema: NARRATIVE_TAROT_RESULT_SCHEMA,
        },
      });
      const rf = body.response_format as {
        type: string;
        json_schema: {
          name: string;
          strict: boolean;
          schema: unknown;
        };
      };
      expect(rf.type).toBe('json_schema');
      expect(rf.json_schema.name).toBe('oracly_tarot_narrative_v2');
      expect(rf.json_schema.strict).toBe(true);
      expect(collectUnsupportedKeys(rf.json_schema.schema)).toEqual([]);
    }
  });
});

describe('6E.4.1 provider error observability', () => {
  async function expectProxy(
    promise: Promise<unknown>,
  ): Promise<ProxyError> {
    try {
      await promise;
    } catch (e) {
      expect(e).toBeInstanceOf(ProxyError);
      return e as ProxyError;
    }
    throw new Error('expected ProxyError');
  }

  it('invalid_json_schema → invalid_request with safe details', async () => {
    const transport = new OpenAiTransport(testConfig(), async () =>
      new Response(
        JSON.stringify({
          error: {
            type: 'invalid_request_error',
            code: 'invalid_json_schema',
            message:
              'Invalid schema for response_format ... uniqueItems ... is not permitted',
          },
        }),
        {
          status: 400,
          headers: {
            'content-type': 'application/json',
            'x-request-id': 'req_test_schema_123',
          },
        },
      ),
    );
    const err = await expectProxy(
      transport.complete({
        model: 'gpt-4o',
        messages: [{ role: 'user', content: 'x' }],
      }),
    );
    expect(err.code).toBe(ErrorCode.invalidRequest);
    expect(err.httpStatus).toBe(400);
    expect(err.details?.requestId).toBe('req_test_schema_123');
    expect(String(err.details?.providerMessage)).toMatch(/invalid_json_schema/i);
    expect(err.details?.httpStatus).toBe(400);
    expect(errorEnvelope(err.code)).toEqual({
      success: false,
      error: { code: ErrorCode.invalidRequest },
    });
  });

  it('generic 5xx → provider_error with safe details', async () => {
    const transport = new OpenAiTransport(testConfig(), async () =>
      new Response(
        JSON.stringify({
          error: {
            type: 'server_error',
            code: 'internal_error',
            message: 'internal provider failure',
          },
        }),
        {
          status: 500,
          headers: {
            'content-type': 'application/json',
            'x-request-id': 'req_test_5xx_456',
          },
        },
      ),
    );
    const err = await expectProxy(
      transport.complete({
        model: 'gpt-4o',
        messages: [{ role: 'user', content: 'x' }],
      }),
    );
    expect(err.code).toBe(ErrorCode.providerError);
    expect(err.httpStatus).toBe(500);
    expect(err.details?.requestId).toBe('req_test_5xx_456');
    expect(String(err.details?.providerMessage)).toMatch(/internal provider failure/i);
    expect(errorEnvelope(err.code).error).toEqual({
      code: ErrorCode.providerError,
    });
    expect(JSON.stringify(errorEnvelope(err.code))).not.toContain(
      'internal provider failure',
    );
  });

  it('redacts Bearer / sk- fragments from providerMessage', async () => {
    const transport = new OpenAiTransport(testConfig(), async () =>
      new Response(
        JSON.stringify({
          error: {
            type: 'server_error',
            message: 'leak Bearer abcdefghijklmnop and sk-abcdefghijklmnopqrstuvwxyz123456',
          },
        }),
        {
          status: 500,
          headers: { 'content-type': 'application/json', 'x-request-id': 'req_redact' },
        },
      ),
    );
    const err = await expectProxy(
      transport.complete({
        model: 'gpt-4o',
        messages: [{ role: 'user', content: 'x' }],
      }),
    );
    const msg = String(err.details?.providerMessage ?? '');
    expect(msg).not.toMatch(/Bearer\s+abcdef/i);
    expect(msg).not.toMatch(/sk-[a-z0-9]{20}/i);
    expect(msg).toContain('[redacted]');
  });
});
