import { beforeEach, describe, expect, it } from 'vitest';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import { extractMessageContent } from '../src/ai/extract-message-content.js';
import { parseCoffeeData } from '../src/ai/parse-provider.js';
import { ProxyError } from '../src/errors.js';
import {
  testApp,
  testConfig,
  coffeeBody,
  coffeeJson,
  coffeeObserverJson,
  coffeeWriterJson,
  openaiReadingSequence,
  authHeader,
} from './helpers.js';

describe('coffee vision empty-response fixes', () => {
  beforeEach(() => readingStageStore.clear());
  it('extracts text from multimodal content parts', () => {
    const text = extractMessageContent([
      {
        type: 'text',
        text: coffeeJson,
      },
    ]);
    expect(text).toContain('genelYorum');
    const parsed = parseCoffeeData(text);
    expect(parsed.visualObservation).toContain('Agiz');
    expect(parsed.overall).toContain('yogun kume');
    expect(parsed.takeaway.length).toBeGreaterThan(20);
  });

  it('rejects coffee JSON without grounded visual observation', () => {
    expect(() =>
      parseCoffeeData(
        '{"genelYorum":"Sakin bir fincan.","sonuc":"Yavas ol."}',
      ),
    ).toThrow(ProxyError);
  });

  it('accepts coffee JSON via content-part provider response', async () => {
    let n = 0;
    const app = await testApp(
      testConfig(),
      async () => {
        n += 1;
        const text = n === 1 ? coffeeObserverJson : coffeeWriterJson;
        return new Response(
          JSON.stringify({
            choices: [
              {
                message: {
                  content: [{ type: 'text', text }],
                },
              },
            ],
          }),
          { status: 200, headers: { 'content-type': 'application/json' } },
        );
      },
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: coffeeBody(),
    });
    expect(res.json().success).toBe(true);
    expect(res.json().data.overall).toContain('yogun kume');
    expect(res.json().data.visualObservation).toContain('Agiz');
    await app.close();
  });
});
