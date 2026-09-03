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
  palmObserverJson,
  palmWriterJson,
  testApp,
  testConfig,
} from './helpers.js';
import { readFileSync } from 'node:fs';
import { errorEnvelope } from '../src/errors.js';

const coffeeNeg = JSON.parse(
  readFileSync('./tests/fixtures/e3g/e3f_coffee_negative.json', 'utf8'),
);
const palmNeg = JSON.parse(
  readFileSync('./tests/fixtures/e3g/e3f_palm_negative.json', 'utf8'),
);
const coffee10 = JSON.parse(
  readFileSync('../tool/e3e_private/evidence/coffee_analysis_e3g_call10_response.json', 'utf8'),
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
