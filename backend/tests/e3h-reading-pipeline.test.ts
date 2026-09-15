import { beforeEach, describe, expect, it } from 'vitest';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import {
  acceptCoffeeObservation,
  acceptPalmObservation,
  bindCoffeeNarrative,
  bindPalmNarrative,
} from '../src/ai/reading/evidence-bind.js';
import { evaluateCoffeeQuality, evaluatePalmQuality } from '../src/ai/human-quality.js';
import { coffeeObserverSystem } from '../src/ai/reading/observer-prompts.js';
import { coffeeWriterSystem } from '../src/ai/reading/writer-prompts.js';
import {
  authHeader,
  coffeeBody,
  coffeeObserverJson,
  coffeeWriterJson,
  openaiReadingSequence,
  palmBody,
  palmObserverJson,
  palmWriterJson,
  testApp,
  testConfig,
} from './helpers.js';
import { readFileSync } from 'node:fs';
import { createHmac } from 'node:crypto';
import { errorEnvelope } from '../src/errors.js';
import { evidenceBoundPersonalization, evidenceThemes } from '../src/ai/reading/pipeline.js';

const coffeeNeg = JSON.parse(
  readFileSync('./tests/fixtures/e3g/e3f_coffee_negative.json', 'utf8'),
);
const palmNeg = JSON.parse(
  readFileSync('./tests/fixtures/e3g/e3f_palm_negative.json', 'utf8'),
);
const coffee10 = JSON.parse(
  readFileSync('./tests/fixtures/e3g_private/coffee_analysis_e3g_call10_response.json', 'utf8'),
);

describe('E3H two-stage reading pipeline', () => {
  beforeEach(() => readingStageStore.clear());

  it('never exposes release diagnostics in production error envelopes', () => {
    const previous = process.env.ORACLY_RELEASE_PHASE;
    process.env.ORACLY_RELEASE_PHASE = 'e3h';
    try {
      expect(
        errorEnvelope('quality_unavailable', {
          stage: 'writer',
          providerResponse: 'must-not-escape',
        }),
      ).toEqual({
        success: false,
        error: { code: 'quality_unavailable' },
      });
    } finally {
      if (previous == null) delete process.env.ORACLY_RELEASE_PHASE;
      else process.env.ORACLY_RELEASE_PHASE = previous;
    }
  });
  it('rejects E3F weak coffee and E3G#10 coffee at human-quality gate', () => {
    expect(evaluateCoffeeQuality(coffeeNeg)).not.toBeNull();
    const d = coffee10.data;
    expect(
      evaluateCoffeeQuality({
        visualObservation: d.visualObservation,
        overall: d.overall,
        love: d.love || '',
        career: d.career || '',
        money: d.money || '',
        nearFuture: d.nearFuture || '',
        takeaway: d.takeaway || '',
        language: 'tr',
      }),
    ).not.toBeNull();
  });

  it('rejects E3F weak palm fixture', () => {
    expect(evaluatePalmQuality(palmNeg)).not.toBeNull();
  });

  it('observer prompts are evidence-only (no fortune leak)', () => {
    const s = coffeeObserverSystem();
    expect(s.includes('No fortune')).toBe(true);
    expect(s.toLowerCase().includes('bulusma')).toBe(false);
  });

  it('writer prompts receive no image instruction', () => {
    const s = coffeeWriterSystem('tr');
    expect(s.includes('evidence JSON only')).toBe(true);
    expect(s.toLowerCase().includes('image_url')).toBe(false);
  });

  it('accepts grounded coffee observation and bound narrative', () => {
    const obs = JSON.parse(coffeeObserverJson);
    expect(acceptCoffeeObservation(obs)).toBeNull();
    const narrative = JSON.parse(coffeeWriterJson);
    expect(bindCoffeeNarrative(narrative, obs)).toBeNull();
  });

  it('accepts grounded palm observation and bound narrative', () => {
    const obs = JSON.parse(palmObserverJson);
    expect(acceptPalmObservation(obs)).toBeNull();
    const narrative = JSON.parse(palmWriterJson);
    expect(bindPalmNarrative(narrative, obs)).toBeNull();
  });

  it('rejects unknown evidence ids', () => {
    const obs = JSON.parse(coffeeObserverJson);
    const narrative = JSON.parse(coffeeWriterJson);
    narrative.overall.evidenceIds = ['missing'];
    expect(bindCoffeeNarrative(narrative, obs)).toBe('unknown_evidence_id');
  });

  it('rejects missing evidence ids on non-empty sections', () => {
    const obs = JSON.parse(coffeeObserverJson);
    const narrative = JSON.parse(coffeeWriterJson);
    narrative.overall.evidenceIds = [];
    expect(bindCoffeeNarrative(narrative, obs)).toBe('missing_evidence_ids');
  });

  it('rejects hedge drop teapot certainty', () => {
    const obs = JSON.parse(coffeeObserverJson);
    const narrative = JSON.parse(coffeeWriterJson);
    narrative.visualObservation.text = 'Ortada bir demlik var ve net gorunuyor.';
    narrative.visualObservation.evidenceIds = ['e1'];
    expect(bindCoffeeNarrative(narrative, obs)).toBe('hedge_dropped');
  });

  it('stage cache avoids repeating observer payload', () => {
    readingStageStore.set('u', 'parent-1', 'coffee_observer', { usable: true });
    expect(readingStageStore.get('u', 'parent-1', 'coffee_observer')).toEqual({
      usable: true,
    });
  });

  it('route uses two-stage sequence and returns public coffee fields', async () => {
    const app = await testApp(
      testConfig(),
      openaiReadingSequence(coffeeObserverJson, coffeeWriterJson),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(), 'idempotency-key': 'e3h-coffee-unit-1' },
      payload: coffeeBody(),
    });
    expect(res.json().success).toBe(true);
    expect(res.json().data.visualObservation).toContain('telve');
    expect(res.json().data.evidenceIds).toBeUndefined();
    expect(res.json().data._e3h).toBeUndefined();
    await app.close();
  });

  it('observe-to-writer seam exposes themes before accepting bounded memory', async () => {
    const observer = JSON.parse(coffeeObserverJson);
    observer.evidence[0].description = 'Two clear residue paths split like a crossroads decision.';
    const app = await testApp(
      testConfig(),
      openaiReadingSequence(JSON.stringify(observer), coffeeWriterJson),
    );
    const observeBody = coffeeBody() as { payload: Record<string, unknown> };
    observeBody.payload.readingPhase = 'observe';
    observeBody.payload.readingBridgeKey = 'bridge-coffee-1';
    const observed = await app.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: { ...authHeader(), 'idempotency-key': 'bridge-coffee-1:observe' },
      payload: observeBody,
    });
    expect(observed.json().data.relevantThemes).toEqual(['decision']);

    const writeBody = coffeeBody() as { payload: Record<string, unknown> };
    delete writeBody.payload.imageBase64;
    delete writeBody.payload.byteLength;
    writeBody.payload.readingPhase = 'write';
    writeBody.payload.readingBridgeKey = 'bridge-coffee-1';
    writeBody.payload.observationToken = observed.json().data.observationToken;
    writeBody.payload.personalization = {
      relevantThemes: ['decision'],
      memorySummary: '[tarot | 2026-09-07 | t1] Prior decision remained open.',
    };
    const written = await app.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: { ...authHeader(), 'idempotency-key': 'bridge-coffee-1:write' },
      payload: writeBody,
    });
    expect(written.json().success).toBe(true);
    await app.close();
  });

  it('signed handoff rejects tampering, expiry, type and operation reuse', async () => {
    const app = await testApp(testConfig(), openaiReadingSequence(coffeeObserverJson, coffeeWriterJson));
    const body = coffeeBody() as { payload: Record<string, unknown> };
    body.payload.readingPhase = 'observe';
    body.payload.readingBridgeKey = 'secure-bridge-a';
    const observed = await app.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: { ...authHeader(), 'idempotency-key': 'secure-observe' }, payload: body,
    });
    const token = observed.json().data.observationToken as string;
    const write = (payload: Record<string, unknown>, key: string) => app.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: { ...authHeader(), 'idempotency-key': key },
      payload: { operation: 'coffee_analysis', payload: {
        language: 'tr', readingPhase: 'write', readingBridgeKey: 'secure-bridge-a', ...payload,
      } },
    });
    expect((await write({ observationToken: `${token}x` }, 'tamper-write')).json().success).toBe(false);
    expect((await write({ observationToken: token, readingBridgeKey: 'secure-bridge-b' }, 'wrong-op-write')).json().success).toBe(false);

    const [encoded] = token.split('.');
    const packet = JSON.parse(Buffer.from(encoded, 'base64url').toString('utf8'));
    packet.expiresAt = Date.now() - 1;
    const expiredBody = Buffer.from(JSON.stringify(packet)).toString('base64url');
    const expiredSig = createHmac('sha256', 'sk-test-server-only').update(expiredBody).digest('base64url');
    expect((await write({ observationToken: `${expiredBody}.${expiredSig}` }, 'expired-write')).json().success).toBe(false);

    const palm = palmBody() as { payload: Record<string, unknown> };
    delete palm.payload.imageBase64;
    delete palm.payload.byteLength;
    Object.assign(palm.payload, {
      readingPhase: 'write', readingBridgeKey: 'secure-bridge-a', observationToken: token,
    });
    const wrongType = await app.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: { ...authHeader(), 'idempotency-key': 'wrong-type-write' }, payload: palm,
    });
    expect(wrongType.json().success).toBe(false);
    await app.close();
  });

  it('derives bounded relevance only from current visual evidence', () => {
    expect(evidenceThemes([
      { description: 'A clear split path resembles a crossroads and decision.' },
      { description: 'A small bird-like mark suggests news or a message.' },
    ])).toEqual(['decision', 'communication']);
    expect(evidenceThemes([
      { description: 'A dense round patch appears near the cup base.' },
    ])).toEqual([]);
    expect(evidenceThemes([
      { description: 'Maybe a split decision path.', confidence: 'low', visibility: 'uncertain' },
      { description: 'Some vague texture is present.', confidence: 'medium', visibility: 'partial' },
    ])).toEqual([]);
  });

  it('strips unrelated memory but retains source attribution for matching evidence', () => {
    const evidence = [{ description: 'A visible split path forms a crossroads decision.' }];
    expect(evidenceBoundPersonalization(evidence, {
      relevantThemes: ['relationship'],
      memorySummary: '[tarot | 2026-09-07 | t1] Unrelated relationship.',
    })).toBeUndefined();
    expect(evidenceBoundPersonalization(evidence, {
      relevantThemes: ['decision'],
      memorySummary: '[tarot | 2026-09-07 | t1] Prior decision remained open.',
    })?.memorySummary).toContain('[tarot | 2026-09-07 | t1]');
  });

  it('config requires reading models for coffee/palm fail-closed when missing', async () => {
    const app = await testApp(
      testConfig({
        OPENAI_READING_VISION_MODEL: '',
        OPENAI_READING_WRITER_MODEL: '',
      }),
      openaiReadingSequence(coffeeObserverJson, coffeeWriterJson),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: coffeeBody(),
    });
    expect(res.json().success).toBe(false);
    expect(res.json().error.code).toBe('no_configuration');
    await app.close();
  });

  it('configured reading models remain fail-closed unless explicitly allowlisted', async () => {
    const app = await testApp(
      testConfig({
        OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-4o-mini',
        OPENAI_READING_VISION_MODEL: 'gpt-5.6-sol',
        OPENAI_READING_WRITER_MODEL: 'gpt-5.6-sol',
      }),
      openaiReadingSequence(coffeeObserverJson, coffeeWriterJson),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: coffeeBody(),
    });
    expect(res.json()).toEqual({
      success: false,
      error: { code: 'no_configuration' },
    });
    await app.close();
  });

  it('accepts palm lines named in description not only region', () => {
    const obs = {
      usable: true,
      reason: 'ok',
      checks: {
        onePalmFacing: true,
        majorLinesVisible: true,
        adequateFocusLight: true,
        overlapOcclusion: false,
        dorsal: false,
      },
      evidence: [
        {
          id: 'p1',
          region: 'central palm',
          description:
            'Heart line curves clearly across the upper palm with continuous path.',
          confidence: 'high',
          visibility: 'clear',
          resemblance: null,
        },
        {
          id: 'p2',
          region: 'mid palm',
          description:
            'Head line runs horizontally with mild curvature and unbroken continuity.',
          confidence: 'high',
          visibility: 'clear',
          resemblance: null,
        },
        {
          id: 'p3',
          region: 'thenar',
          description:
            'Life line arcs around the thumb mound with a long continuous sweep.',
          confidence: 'medium',
          visibility: 'clear',
          resemblance: null,
        },
      ],
    };
    expect(acceptPalmObservation(obs)).toBeNull();
  });

});
