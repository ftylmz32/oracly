/** Phase 6D — Narrative V2 request/result contract tests. */
import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { authHeader, testApp, testConfig } from './helpers.js';
import { NARRATIVE_SCHEMA_NAME } from '../src/ai/narrative-tarot-limits.js';

const fixturePath = resolve(
  process.cwd(),
  '../test/fixtures/tarot_narrative_prompt_v1.json',
);
const fixture = JSON.parse(readFileSync(fixturePath, 'utf8')) as {
  scenarios: { id: string; modelInput: Record<string, unknown> }[];
};

function narrativeOf(id: string): Record<string, unknown> {
  const s = fixture.scenarios.find((x) => x.id === id);
  if (!s) throw new Error(`missing fixture ${id}`);
  return structuredClone(s.modelInput);
}

function narrativeBody(narrative: Record<string, unknown>, language = 'en') {
  return {
    operation: 'tarot_reading',
    payload: {
      mode: 'narrative_v2',
      contractVersion: 1,
      language,
      narrative: { ...narrative, languageCode: language },
    },
  };
}

function prose(n = 40): string {
  return `A calm reflective note about presence and choice ${'x'.repeat(Math.max(0, n - 40))}`;
}

function validResultFor(narrative: Record<string, unknown>) {
  const cards = narrative.cards as { canonicalCardId: string; positionKey: string }[];
  const relationships = (narrative.relationships ?? []) as {
    leftCardId: string;
    rightCardId: string;
    kind: string;
  }[];
  const recurringCards = (narrative.recurringCards ?? []) as {
    canonicalCardId: string;
  }[];
  const recurringThemes = (narrative.recurringThemes ?? []) as {
    themeIdOrLabel: string;
  }[];
  const memory = narrative.memory as { included: boolean; entries: unknown[] };
  return {
    contractVersion: 1,
    languageCode: narrative.languageCode,
    summary: prose(80),
    cardReadings: cards.map((c) => ({
      cardId: c.canonicalCardId,
      positionKey: c.positionKey,
      text: prose(60),
    })),
    synthesis: prose(90),
    relationshipInsights: relationships.slice(0, 1).map((r) => ({
      leftCardId: r.leftCardId,
      rightCardId: r.rightCardId,
      kind: r.kind,
      text: prose(50),
    })),
    recurringCardInsights: recurringCards.slice(0, 1).map((c) => ({
      cardId: c.canonicalCardId,
      text: prose(50),
    })),
    recurringThemeInsights: recurringThemes.slice(0, 1).map((t) => ({
      themeIdOrLabel: t.themeIdOrLabel,
      text: prose(50),
    })),
    memoryInsights:
      memory.included && memory.entries.length > 0
        ? [{ memoryIndex: 0, text: prose(50) }]
        : [],
    lifeAreas: [{ kind: 'love', text: prose(50) }],
    advice: prose(50),
    reflectionPrompt: null,
    dailyFocus: null,
    closingMessage: prose(50),
  };
}

describe('narrative_v2 tarot contract', () => {
  it('accepts a valid Narrative request and returns structured result', async () => {
    const narrative = narrativeOf('classical_three_en_decision');
    const result = validResultFor(narrative);
    let seenBody = '';
    const app = await testApp(testConfig(), async (_url, init) => {
      seenBody = String(init?.body ?? '');
      return new Response(
        JSON.stringify({ choices: [{ message: { content: JSON.stringify(result) } }] }),
        { status: 200, headers: { 'content-type': 'application/json' } },
      );
    });
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: narrativeBody(narrative, 'en'),
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().success).toBe(true);
    expect(res.json().data.contractVersion).toBe(1);
    expect(res.json().data.text).toBeUndefined();
    expect(res.json().data.cardReadings).toHaveLength(3);
    expect(seenBody).toContain('"type":"json_schema"');
    expect(seenBody).toContain(NARRATIVE_SCHEMA_NAME);
    expect(seenBody).toContain('"strict":true');
    expect(seenBody).toContain('classical.threeCard');
    await app.close();
  });

  it('rejects wrong contractVersion / policy / language mismatch / unknown keys', async () => {
    const app = await testApp(testConfig({ AI_DEV_AUTH_BYPASS: 'true' }));
    const base = narrativeOf('classical_single_en_open');

    const badVersion = narrativeBody(base, 'en');
    (badVersion.payload as { contractVersion: number }).contractVersion = 2;
    expect(
      (
        await app.inject({
          method: 'POST',
          url: '/v1/ai/complete',
          headers: { 'content-type': 'application/json' },
          payload: badVersion,
        })
      ).json().error.code,
    ).toBe('invalid_request');

    const badLang = narrativeBody(base, 'en');
    (badLang.payload as { language: string }).language = 'tr';
    expect(
      (
        await app.inject({
          method: 'POST',
          url: '/v1/ai/complete',
          headers: { 'content-type': 'application/json' },
          payload: badLang,
        })
      ).json().error.code,
    ).toBe('invalid_request');

    const withOwner = narrativeBody(
      { ...base, ownerId: 'user_1' } as Record<string, unknown>,
      'en',
    );
    expect(
      (
        await app.inject({
          method: 'POST',
          url: '/v1/ai/complete',
          headers: { 'content-type': 'application/json' },
          payload: withOwner,
        })
      ).json().error.code,
    ).toBe('invalid_request');

    const mixed = {
      operation: 'tarot_reading',
      payload: {
        mode: 'narrative_v2',
        contractVersion: 1,
        language: 'en',
        narrative: base,
        cards: [{ name: 'x' }],
      },
    };
    expect(
      (
        await app.inject({
          method: 'POST',
          url: '/v1/ai/complete',
          headers: { 'content-type': 'application/json' },
          payload: mixed,
        })
      ).json().error.code,
    ).toBe('invalid_request');

    const unknownMode = {
      operation: 'tarot_reading',
      payload: { mode: 'narrative_v3', language: 'en', narrative: base },
    };
    expect(
      (
        await app.inject({
          method: 'POST',
          url: '/v1/ai/complete',
          headers: { 'content-type': 'application/json' },
          payload: unknownMode,
        })
      ).json().error.code,
    ).toBe('invalid_request');

    await app.close();
  });

  it('rejects malformed provider JSON without legacy fallback', async () => {
    const narrative = narrativeOf('classical_single_en_open');
    const app = await testApp(testConfig(), async () => {
      return new Response(
        JSON.stringify({
          choices: [{ message: { content: '{"summary":"only"}' } }],
        }),
        { status: 200, headers: { 'content-type': 'application/json' } },
      );
    });
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: narrativeBody(narrative, 'en'),
    });
    expect(res.json().success).toBe(false);
    expect(res.json().error.code).toBe('invalid_response');
    expect(res.json().data?.text).toBeUndefined();
    await app.close();
  });

  it('rejects fake relationship / wrong card coverage', async () => {
    const narrative = narrativeOf('classical_three_en_decision');
    const bad = validResultFor(narrative);
    bad.relationshipInsights = [
      {
        leftCardId: 'major_00',
        rightCardId: 'major_01',
        kind: 'invented',
        text: prose(50),
      },
    ];
    const app = await testApp(testConfig(), async () => {
      return new Response(
        JSON.stringify({
          choices: [{ message: { content: JSON.stringify(bad) } }],
        }),
        { status: 200, headers: { 'content-type': 'application/json' } },
      );
    });
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: narrativeBody(narrative, 'en'),
    });
    expect(res.json().error.code).toBe('invalid_response');
    await app.close();
  });
});
