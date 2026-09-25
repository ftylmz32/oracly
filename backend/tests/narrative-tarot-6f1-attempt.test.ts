/**
 * Phase 6F.1 — Narrative V2 attempt-aware idempotency / duplicate / a3 reject.
 * REAL PROVIDER CALLS = 0 (fake OpenAI fetch).
 */
import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  appCheckHeader,
  authHeader,
  signHs256,
  StaticAppCheckVerifier,
  testApp,
  testConfig,
} from './helpers.js';
import {
  parseNarrativeAttemptFromIdempotency,
  narrativeDuplicateFingerprint,
  requireNarrativeAttemptInLockedEnv,
} from '../src/narrative-tarot-attempt.js';
import { loadConfig } from '../src/config.js';
import { ProxyError, ErrorCode } from '../src/errors.js';

const fixturePath = resolve(
  process.cwd(),
  '../test/fixtures/tarot_narrative_prompt_v1.json',
);
const fixture = JSON.parse(readFileSync(fixturePath, 'utf8')) as {
  scenarios: { id: string; modelInput: Record<string, unknown> }[];
};

const JWT = {
  secret: 'unit-test-jwt-secret-6f1',
  iss: 'https://issuer.example',
  aud: 'oracly-ai',
} as const;

function narrativeOf(id: string): Record<string, unknown> {
  const s = fixture.scenarios.find((x) => x.id === id);
  if (!s) throw new Error(`missing fixture ${id}`);
  return structuredClone(s.modelInput);
}

function prose(n = 40): string {
  return `A calm reflective note about presence and choice ${'x'.repeat(Math.max(0, n - 40))}`;
}

function validResultFor(narrative: Record<string, unknown>) {
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
    memoryInsights: [],
    lifeAreas: [],
    advice: prose(50),
    reflectionPrompt: null,
    dailyFocus: null,
    closingMessage: prose(50),
  };
}

function narrativeBody(narrative: Record<string, unknown>) {
  return {
    operation: 'tarot_reading',
    payload: {
      mode: 'narrative_v2',
      contractVersion: 1,
      language: 'en',
      narrative: { ...narrative, languageCode: 'en' },
    },
  };
}

function lockedNarrativeConfig() {
  return testConfig({
    APP_ENV: 'staging',
    AI_JWT_SECRET: JWT.secret,
    AI_JWT_ISSUER: JWT.iss,
    AI_JWT_AUDIENCE: JWT.aud,
    OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-5.6-sol',
    OPENAI_TAROT_NARRATIVE_MODEL: 'gpt-5.6-sol',
    OPENAI_TAROT_NARRATIVE_REASONING_EFFORT: 'none',
    READING_STAGING_BUCKET: 'test-reading-staging',
    READING_TASK_QUEUE: 'test-reading-queue',
    READING_TASK_TARGET_URL:
      'https://example.test/internal/reading-tasks/process',
    READING_TASK_SERVICE_ACCOUNT: 'worker@example.test',
  });
}

function lockedAuthHeaders(idempotencyKey: string) {
  return {
    ...authHeader(
      signHs256(JWT.secret, { iss: JWT.iss, aud: JWT.aud }),
    ),
    ...appCheckHeader('6f1-app-check'),
    'idempotency-key': idempotencyKey,
  };
}

describe('narrative-tarot-attempt helpers', () => {
  it('parses only a1/a2 suffixes', () => {
    expect(parseNarrativeAttemptFromIdempotency('base:nv2:a1')).toBe(1);
    expect(parseNarrativeAttemptFromIdempotency('base:nv2:a2')).toBe(2);
    expect(parseNarrativeAttemptFromIdempotency('base:nv2:a3')).toBeNull();
    expect(parseNarrativeAttemptFromIdempotency('base:nv2:a0')).toBeNull();
    expect(parseNarrativeAttemptFromIdempotency('base')).toBeNull();
  });

  it('duplicate fingerprints isolate attempts', () => {
    expect(narrativeDuplicateFingerprint('sem', 1)).toBe('sem:attempt-1');
    expect(narrativeDuplicateFingerprint('sem', 2)).toBe('sem:attempt-2');
  });

  it('locked env rejects missing/invalid attempt', () => {
    const locked = loadConfig({
      APP_ENV: 'production',
      OPENAI_API_KEY: 'sk-test',
      OPENAI_MODEL: 'gpt-4o',
      OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-5.6-sol',
      OPENAI_READING_VISION_MODEL: 'gpt-5.6-sol',
      OPENAI_READING_WRITER_MODEL: 'gpt-5.6-sol',
      OPENAI_READING_REASONING_EFFORT: 'none',
      OPENAI_TAROT_NARRATIVE_MODEL: 'gpt-5.6-sol',
      OPENAI_TAROT_NARRATIVE_REASONING_EFFORT: 'none',
      AI_AUTH_REQUIRED: 'true',
      AI_JWT_SECRET: JWT.secret,
      AI_JWT_ISSUER: JWT.iss,
      AI_JWT_AUDIENCE: JWT.aud,
      READING_STAGING_BUCKET: 'test-reading-staging',
      READING_TASK_QUEUE: 'test-reading-queue',
      READING_TASK_TARGET_URL:
        'https://example.test/internal/reading-tasks/process',
      READING_TASK_SERVICE_ACCOUNT: 'worker@example.test',
    } as NodeJS.ProcessEnv);
    expect(() =>
      requireNarrativeAttemptInLockedEnv(locked, 'base:nv2:a3'),
    ).toThrow(ProxyError);
    try {
      requireNarrativeAttemptInLockedEnv(locked, 'base:nv2:a3');
    } catch (e) {
      expect((e as ProxyError).code).toBe(ErrorCode.invalidRequest);
    }
    expect(() => requireNarrativeAttemptInLockedEnv(locked, 'base')).toThrow(
      ProxyError,
    );
    expect(requireNarrativeAttemptInLockedEnv(locked, 'base:nv2:a1')).toBe(1);
  });
});

describe('Narrative V2 route attempt idempotency', () => {
  const three = () => narrativeOf('classical_three_en_decision');

  it('a1 then a2 → two provider invocations (no replay of a1)', async () => {
    let calls = 0;
    const narrative = three();
    const app = await testApp(testConfig(), async () => {
      calls += 1;
      return new Response(
        JSON.stringify({
          choices: [
            {
              message: {
                content: JSON.stringify(validResultFor(narrative)),
              },
            },
          ],
        }),
        { status: 200, headers: { 'content-type': 'application/json' } },
      );
    });
    const body = narrativeBody(narrative);
    const headers = authHeader();
    const r1 = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...headers, 'idempotency-key': 'paid-base-6f1:nv2:a1' },
      payload: body,
    });
    expect(r1.json().success).toBe(true);
    const r2 = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...headers, 'idempotency-key': 'paid-base-6f1:nv2:a2' },
      payload: body,
    });
    expect(r2.json().success).toBe(true);
    expect(calls).toBe(2);
    await app.close();
  });

  it('same a1 twice → provider once (response replay)', async () => {
    let calls = 0;
    const narrative = three();
    const app = await testApp(testConfig(), async () => {
      calls += 1;
      return new Response(
        JSON.stringify({
          choices: [
            {
              message: {
                content: JSON.stringify(validResultFor(narrative)),
              },
            },
          ],
        }),
        { status: 200, headers: { 'content-type': 'application/json' } },
      );
    });
    const body = narrativeBody(narrative);
    const headers = {
      ...authHeader(),
      'idempotency-key': 'paid-base-6f1-replay:nv2:a1',
    };
    const r1 = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers,
      payload: body,
    });
    expect(r1.json().success).toBe(true);
    const r2 = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers,
      payload: body,
    });
    expect(r2.json().success).toBe(true);
    expect(calls).toBe(1);
    await app.close();
  });

  it('locked a3 → provider 0 + invalid_request', async () => {
    let calls = 0;
    const narrative = three();
    const app = await testApp(
      lockedNarrativeConfig(),
      async () => {
        calls += 1;
        return new Response(
          JSON.stringify({
            choices: [
              {
                message: {
                  content: JSON.stringify(validResultFor(narrative)),
                },
              },
            ],
          }),
          { status: 200, headers: { 'content-type': 'application/json' } },
        );
      },
      { appCheck: new StaticAppCheckVerifier('6f1-app-check') },
    );
    const r = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: lockedAuthHeaders('paid-base-6f1:nv2:a3'),
      payload: narrativeBody(narrative),
    });
    expect(r.json().success).toBe(false);
    expect(r.json().error.code).toBe('invalid_request');
    expect(calls).toBe(0);
    await app.close();
  });
});
