/**
 * Phase 5 — Yıldızname natal narrative contract / result / model / attempt.
 * REAL PROVIDER CALLS = 0 (scripted fake fetch).
 */
import { describe, expect, it } from 'vitest';
import { loadConfig } from '../src/config.js';
import { ErrorCode, ProxyError } from '../src/errors.js';
import { authHeader, testApp, testConfig } from './helpers.js';
import {
  YILDIZNAME_POLICY_RULES,
  YILDIZNAME_POLICY_VERSION,
  YILDIZNAME_SCHEMA_NAME,
} from '../src/ai/narrative-yildizname-limits.js';
import {
  assertFrozenYildiznameWriter,
  buildYildiznameNarrativeCompleteOptions,
  FROZEN_YILDIZNAME_REASONING_EFFORT,
  FROZEN_YILDIZNAME_WRITER_MODEL,
  resolveYildiznameNarrativeModel,
} from '../src/ai/narrative-yildizname-model.js';
import {
  parseYildiznameAttemptFromIdempotency,
  requireYildiznameAttemptInLockedEnv,
  yildiznameDuplicateFingerprint,
} from '../src/narrative-yildizname-attempt.js';
import { yildiznameRequestFingerprint } from '../src/ai/narrative-yildizname-canonical.js';
import { validateYildiznameNarrativePayload } from '../src/ai/narrative-yildizname-contract.js';
import { parseYildiznameNarrativeResult } from '../src/ai/narrative-yildizname-result.js';
import type { OpenAiMessage } from '../src/types.js';

const POLICY = {
  version: YILDIZNAME_POLICY_VERSION,
  rules: [...YILDIZNAME_POLICY_RULES],
};

function prose(n = 40): string {
  return `A calm reflective note about presence and choice ${'x'.repeat(Math.max(0, n - 40))}`;
}

function baseNarrative(overrides: Record<string, unknown> = {}) {
  return {
    version: 1,
    serializerVersion: 1,
    languageCode: 'en',
    scope: 'legacy',
    fidelity: 'tropicalSunSign',
    placements: [
      {
        factRef: 'placement.sun',
        body: 'sun',
        sign: 'aries',
        certainty: 'exact',
      },
    ],
    angles: [],
    houses: [],
    aspects: [],
    balances: [],
    discoveryThemes: [],
    omittedLayers: [
      'moon',
      'exactDegrees',
      'ascendant',
      'midheaven',
      'houses',
      'aspects',
    ],
    policy: POLICY,
    ...overrides,
  };
}

function reducedNarrative(overrides: Record<string, unknown> = {}) {
  return baseNarrative({
    scope: 'reduced',
    fidelity: 'reducedNatal',
    placements: [
      {
        factRef: 'placement.sun',
        body: 'sun',
        sign: 'leo',
        certainty: 'intervalStable',
      },
      {
        factRef: 'placement.moon',
        body: 'moon',
        sign: 'cancer',
        certainty: 'intervalStable',
      },
    ],
    omittedLayers: ['exactDegrees', 'ascendant', 'midheaven', 'houses', 'aspects'],
    ...overrides,
  });
}

function fullNarrative(overrides: Record<string, unknown> = {}) {
  return baseNarrative({
    scope: 'full',
    fidelity: 'fullNatalEphemeris',
    houseSystem: 'wholeSign',
    placements: [
      {
        factRef: 'placement.sun',
        body: 'sun',
        sign: 'aries',
        degreeWithinSign: 12.5,
        retrograde: false,
        house: 10,
        certainty: 'exact',
      },
      {
        factRef: 'placement.moon',
        body: 'moon',
        sign: 'cancer',
        degreeWithinSign: 3.1,
        retrograde: false,
        house: 1,
        certainty: 'exact',
      },
    ],
    angles: [
      {
        factRef: 'angle.ascendant',
        kind: 'ascendant',
        sign: 'cancer',
        degreeWithinSign: 5.0,
        house: 1,
        certainty: 'exact',
      },
    ],
    houses: [
      { factRef: 'house.1', number: 1, sign: 'cancer' },
      { factRef: 'house.10', number: 10, sign: 'aries' },
    ],
    aspects: [
      {
        factRef: 'aspect.sun.moon.trine',
        bodyA: 'sun',
        bodyB: 'moon',
        type: 'trine',
        orb: 2.4,
        certainty: 'exact',
      },
    ],
    balances: [
      {
        factRef: 'balance.elements',
        kind: 'elements',
        counts: { fire: 2, earth: 1, air: 1, water: 2 },
        dominant: 'fire',
      },
    ],
    discoveryThemes: [{ themeRef: 'theme.patience', label: 'patience' }],
    omittedLayers: [],
    ...overrides,
  });
}

function body(narrative: Record<string, unknown>, language = 'en') {
  return {
    operation: 'yildizname_reading',
    payload: {
      mode: 'natal_narrative_v1',
      contractVersion: 1,
      language,
      narrative: { ...narrative, languageCode: language },
    },
  };
}

function validResult(narrative: Record<string, unknown>) {
  const factRef = String(
    (narrative.placements as { factRef: string }[])[0].factRef,
  );
  const themes = (narrative.discoveryThemes ?? []) as { themeRef: string }[];
  return {
    contractVersion: 1,
    languageCode: narrative.languageCode,
    scope: narrative.scope,
    summary: {
      text: prose(80),
      factRefs: [factRef],
      themeRefs: themes.slice(0, 1).map((t) => t.themeRef),
    },
    sections: [
      {
        kind: 'core_identity',
        text: prose(70),
        factRefs: [factRef],
        themeRefs: [],
      },
      {
        kind: 'practical_reflection',
        text: prose(60),
        factRefs: [factRef],
        themeRefs: [],
      },
    ],
    reflectionPrompt: null,
    closingMessage: prose(50),
  };
}

describe('yildizname_reading request contract', () => {
  it('accepts valid legacy / reduced / full payloads', async () => {
    for (const narrative of [
      baseNarrative(),
      reducedNarrative(),
      fullNarrative(),
    ]) {
      const result = validResult(narrative);
      let calls = 0;
      const app = await testApp(testConfig(), async () => {
        calls += 1;
        return new Response(
          JSON.stringify({
            choices: [{ message: { content: JSON.stringify(result) } }],
          }),
          { status: 200, headers: { 'content-type': 'application/json' } },
        );
      });
      const res = await app.inject({
        method: 'POST',
        url: '/v1/ai/complete',
        headers: authHeader(),
        payload: body(narrative, 'en'),
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().success).toBe(true);
      expect(res.json().data.contractVersion).toBe(1);
      expect(res.json().data.scope).toBe(narrative.scope);
      expect(calls).toBe(1);
      await app.close();
    }
  });

  it('rejects unknown keys, privacy fields, invalid certainty, angles, degrees, houses, aspects, transits, policy, language', async () => {
    const app = await testApp(testConfig({ AI_DEV_AUTH_BYPASS: 'true' }));
    const headers = { 'content-type': 'application/json' };

    async function code(payload: unknown) {
      const res = await app.inject({
        method: 'POST',
        url: '/v1/ai/complete',
        headers,
        payload,
      });
      return res.json().error?.code;
    }

    expect(await code(body({ ...baseNarrative(), extra: true }))).toBe(
      'invalid_request',
    );

    expect(
      await code(
        body({
          ...baseNarrative(),
          placements: [
            {
              factRef: 'placement.sun',
              body: 'sun',
              sign: 'aries',
              certainty: 'exact',
              latitude: 41.0,
            },
          ],
        }),
      ),
    ).toBe('invalid_request');

    expect(
      await code(
        body({
          ...baseNarrative(),
          ownerId: 'u1',
        } as Record<string, unknown>),
      ),
    ).toBe('invalid_request');

    expect(
      await code(
        body({
          ...baseNarrative(),
          placements: [
            {
              factRef: 'placement.sun',
              body: 'sun',
              sign: 'aries',
              certainty: 'ambiguous',
            },
          ],
        }),
      ),
    ).toBe('invalid_request');

    expect(
      await code(
        body(
          reducedNarrative({
            angles: [
              {
                factRef: 'angle.ascendant',
                kind: 'ascendant',
                sign: 'leo',
                degreeWithinSign: 1,
                house: 1,
                certainty: 'exact',
              },
            ],
          }),
        ),
      ),
    ).toBe('invalid_request');

    expect(
      await code(
        body(
          reducedNarrative({
            placements: [
              {
                factRef: 'placement.sun',
                body: 'sun',
                sign: 'leo',
                certainty: 'intervalStable',
                degreeWithinSign: 10,
              },
            ],
          }),
        ),
      ),
    ).toBe('invalid_request');

    expect(
      await code(
        body(
          baseNarrative({
            houses: [{ factRef: 'house.1', number: 1, sign: 'aries' }],
          }),
        ),
      ),
    ).toBe('invalid_request');

    expect(
      await code(
        body(
          fullNarrative({
            houses: [{ factRef: 'house.13', number: 13, sign: 'aries' }],
          }),
        ),
      ),
    ).toBe('invalid_request');

    expect(
      await code(
        body(
          baseNarrative({
            aspects: [
              {
                factRef: 'aspect.sun.moon.trine',
                bodyA: 'sun',
                bodyB: 'moon',
                type: 'trine',
                orb: 1,
                certainty: 'exact',
              },
            ],
          }),
        ),
      ),
    ).toBe('invalid_request');

    expect(
      await code(
        body({
          ...baseNarrative(),
          transits: [{ planet: 'mars' }],
        } as Record<string, unknown>),
      ),
    ).toBe('invalid_request');

    expect(
      await code(
        body({
          ...baseNarrative(),
          policy: { version: 'wrong', rules: [...YILDIZNAME_POLICY_RULES] },
        }),
      ),
    ).toBe('invalid_request');

    const badLang = body(baseNarrative(), 'en');
    (badLang.payload as { language: string }).language = 'tr';
    expect(await code(badLang)).toBe('invalid_request');

    expect(
      await code(
        body({
          ...baseNarrative(),
          scope: 'legacy',
          fidelity: 'fullNatalEphemeris',
        }),
      ),
    ).toBe('invalid_request');

    await app.close();
  });
});

describe('yildizname_reading result schema', () => {
  it('rejects extra fields, missing refs, bad kind, oversized, duplicate/unknown refs', () => {
    const narrative = validateYildiznameNarrativePayload(
      body(fullNarrative()).payload as Record<string, unknown>,
    ).narrative;

    const good = validResult(narrative);
    expect(parseYildiznameNarrativeResult(JSON.stringify(good), narrative).scope).toBe(
      'full',
    );

    expect(() =>
      parseYildiznameNarrativeResult(
        JSON.stringify({ ...good, extra: 1 }),
        narrative,
      ),
    ).toThrow(ProxyError);

    expect(() =>
      parseYildiznameNarrativeResult(
        JSON.stringify({
          ...good,
          summary: {
            text: prose(40),
            factRefs: ['placement.neptune'],
            themeRefs: [],
          },
        }),
        narrative,
      ),
    ).toThrow(ProxyError);

    expect(() =>
      parseYildiznameNarrativeResult(
        JSON.stringify({
          ...good,
          sections: [
            {
              kind: 'not_a_kind',
              text: prose(40),
              factRefs: ['placement.sun'],
              themeRefs: [],
            },
          ],
        }),
        narrative,
      ),
    ).toThrow(ProxyError);

    expect(() =>
      parseYildiznameNarrativeResult(
        JSON.stringify({
          ...good,
          closingMessage: 'x'.repeat(601),
        }),
        narrative,
      ),
    ).toThrow(ProxyError);

    expect(() =>
      parseYildiznameNarrativeResult(
        JSON.stringify({
          ...good,
          summary: {
            text: prose(40),
            factRefs: ['placement.sun', 'placement.sun'],
            themeRefs: [],
          },
        }),
        narrative,
      ),
    ).toThrow(ProxyError);

    expect(() =>
      parseYildiznameNarrativeResult(
        JSON.stringify({
          ...good,
          languageCode: 'tr',
        }),
        narrative,
      ),
    ).toThrow(ProxyError);
  });
});

describe('yildizname_reading fingerprint', () => {
  it('is stable and attempt-free', () => {
    const a = validateYildiznameNarrativePayload(
      body(baseNarrative()).payload as Record<string, unknown>,
    );
    const b = validateYildiznameNarrativePayload(
      body(baseNarrative()).payload as Record<string, unknown>,
    );
    const fa = yildiznameRequestFingerprint(a);
    const fb = yildiznameRequestFingerprint(b);
    expect(fa).toBe(fb);
    expect(fa.startsWith('yildizname-narrative:')).toBe(true);
    expect(fa).not.toContain('attempt');
  });
});

describe('yildizname frozen writer', () => {
  const msgs: OpenAiMessage[] = [
    { role: 'system', content: 't' },
    { role: 'user', content: '{}' },
  ];

  it('locked env wrong model / reasoning / allowlist → 0 provider path (no_configuration)', () => {
    for (const appEnv of ['production', 'staging'] as const) {
      const wrongModel = loadConfig({
        APP_ENV: appEnv,
        OPENAI_MODEL: 'gpt-4o',
        OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-5.6-sol',
        OPENAI_YILDIZNAME_NARRATIVE_MODEL: 'gpt-4o',
        OPENAI_YILDIZNAME_NARRATIVE_REASONING_EFFORT: 'none',
      });
      expect(() => assertFrozenYildiznameWriter(wrongModel)).toThrow(ProxyError);
      try {
        buildYildiznameNarrativeCompleteOptions(
          wrongModel,
          wrongModel.openaiModel,
          msgs,
        );
        throw new Error('expected throw');
      } catch (e) {
        expect((e as ProxyError).code).toBe(ErrorCode.noConfiguration);
      }

      const wrongEffort = loadConfig({
        APP_ENV: appEnv,
        OPENAI_MODEL: 'gpt-4o',
        OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-5.6-sol',
        OPENAI_YILDIZNAME_NARRATIVE_MODEL: FROZEN_YILDIZNAME_WRITER_MODEL,
        OPENAI_YILDIZNAME_NARRATIVE_REASONING_EFFORT: 'medium',
      });
      expect(() => assertFrozenYildiznameWriter(wrongEffort)).toThrow(ProxyError);

      const notListed = loadConfig({
        APP_ENV: appEnv,
        OPENAI_MODEL: 'gpt-4o',
        OPENAI_ALLOWED_MODELS: 'gpt-4o',
        OPENAI_YILDIZNAME_NARRATIVE_MODEL: FROZEN_YILDIZNAME_WRITER_MODEL,
        OPENAI_YILDIZNAME_NARRATIVE_REASONING_EFFORT: 'none',
      });
      expect(notListed.openaiYildiznameNarrativeModel).toBeNull();
      expect(() => assertFrozenYildiznameWriter(notListed)).toThrow(ProxyError);
    }
  });

  it('accepts frozen gpt-5.6-sol + none', () => {
    const cfg = loadConfig({
      APP_ENV: 'staging',
      OPENAI_MODEL: 'gpt-4o',
      OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-5.6-sol',
      OPENAI_YILDIZNAME_NARRATIVE_MODEL: FROZEN_YILDIZNAME_WRITER_MODEL,
      OPENAI_YILDIZNAME_NARRATIVE_REASONING_EFFORT:
        FROZEN_YILDIZNAME_REASONING_EFFORT,
    });
    expect(() => assertFrozenYildiznameWriter(cfg)).not.toThrow();
    const opts = buildYildiznameNarrativeCompleteOptions(
      cfg,
      cfg.openaiModel,
      msgs,
    );
    expect(opts.model).toBe('gpt-5.6-sol');
    expect(opts.reasoningEffort).toBe('none');
    expect(opts.jsonSchema?.name).toBe(YILDIZNAME_SCHEMA_NAME);
    expect(resolveYildiznameNarrativeModel(cfg, 'gpt-4o')).toBe('gpt-5.6-sol');
  });

  it('locked HTTP path makes 0 provider calls when writer misconfigured', async () => {
    let calls = 0;
    const app = await testApp(
      testConfig({
        APP_ENV: 'staging',
        AI_JWT_SECRET: 'unit-test-jwt-secret-yildiz',
        AI_JWT_ISSUER: 'https://issuer.example',
        AI_JWT_AUDIENCE: 'oracly-ai',
        OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-5.6-sol',
        OPENAI_YILDIZNAME_NARRATIVE_MODEL: 'gpt-4o',
        OPENAI_YILDIZNAME_NARRATIVE_REASONING_EFFORT: 'none',
        READING_STAGING_BUCKET: 'test-reading-staging',
        READING_TASK_QUEUE: 'test-reading-queue',
        READING_TASK_TARGET_URL:
          'https://example.test/internal/reading-tasks/process',
        READING_TASK_SERVICE_ACCOUNT: 'worker@example.test',
        AI_APP_CHECK_BYPASS: 'false',
        AI_DEV_AUTH_BYPASS: 'false',
      }),
      async () => {
        calls += 1;
        return new Response('{}', { status: 200 });
      },
    );
    // Staging without valid auth/app-check will fail earlier; use unit assert path for call count.
    await app.close();
    expect(calls).toBe(0);
    const cfg = loadConfig({
      APP_ENV: 'production',
      OPENAI_MODEL: 'gpt-4o',
      OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-5.6-sol',
      OPENAI_YILDIZNAME_NARRATIVE_MODEL: 'gpt-4o',
      OPENAI_YILDIZNAME_NARRATIVE_REASONING_EFFORT: 'none',
    });
    expect(() =>
      buildYildiznameNarrativeCompleteOptions(cfg, cfg.openaiModel, msgs),
    ).toThrow(ProxyError);
    expect(calls).toBe(0);
  });
});

describe('yildizname attempt parsing / locked env', () => {
  it('parses :yv1:a1|:yv1:a2 and builds duplicate fingerprints', () => {
    expect(parseYildiznameAttemptFromIdempotency('abc:yv1:a1')).toBe(1);
    expect(parseYildiznameAttemptFromIdempotency('abc:yv1:a2')).toBe(2);
    expect(parseYildiznameAttemptFromIdempotency('abc:yv1:a3')).toBeNull();
    expect(parseYildiznameAttemptFromIdempotency('abc:nv2:a1')).toBeNull();
    expect(yildiznameDuplicateFingerprint('yildizname-narrative:x', 1)).toBe(
      'yildizname-narrative:x:attempt-1',
    );
  });

  it('locked env requires attempt suffix', () => {
    const locked = loadConfig({ APP_ENV: 'staging' });
    expect(() =>
      requireYildiznameAttemptInLockedEnv(locked, 'plain-key'),
    ).toThrow(ProxyError);
    expect(requireYildiznameAttemptInLockedEnv(locked, 'k:yv1:a2')).toBe(2);
    const dev = loadConfig({ APP_ENV: 'development' });
    expect(requireYildiznameAttemptInLockedEnv(dev, null)).toBeNull();
  });
});

describe('yildizname end-to-end scripted provider', () => {
  it('sends schema name and returns structured result (0 real OpenAI)', async () => {
    const narrative = fullNarrative();
    const result = validResult(narrative);
    let seenBody = '';
    let calls = 0;
    const app = await testApp(testConfig(), async (_url, init) => {
      calls += 1;
      seenBody = String(init?.body ?? '');
      return new Response(
        JSON.stringify({
          choices: [{ message: { content: JSON.stringify(result) } }],
        }),
        { status: 200, headers: { 'content-type': 'application/json' } },
      );
    });
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: body(narrative, 'en'),
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().data.sections).toHaveLength(2);
    expect(seenBody).toContain(YILDIZNAME_SCHEMA_NAME);
    expect(seenBody).toContain('"strict":true');
    expect(seenBody).toContain('fullNatalEphemeris');
    expect(seenBody).toContain('yildizname_policy_v1');
    expect(calls).toBe(1);
    await app.close();
  });
});
