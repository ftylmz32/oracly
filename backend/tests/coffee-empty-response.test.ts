import { describe, expect, it } from 'vitest';
import { extractMessageContent } from '../src/ai/extract-message-content.js';
import { parseCoffeeData } from '../src/ai/parse-provider.js';
import { openaiText, testApp, testConfig, coffeeBody, authHeader } from './helpers.js';

describe('coffee vision empty-response fixes', () => {
  it('extracts text from multimodal content parts', () => {
    const text = extractMessageContent([
      { type: 'text', text: '{"genelYorum":"Sakin bir fincan.","sonuc":"Yavas ol."}' },
    ]);
    expect(text).toContain('genelYorum');
    const parsed = parseCoffeeData(text);
    expect(parsed.overall).toContain('Sakin');
    expect(parsed.takeaway).toContain('Yavas');
  });

  it('accepts coffee JSON via content-part provider response', async () => {
    const json =
      '{"gorselTespit":"ince izler","genelYorum":"Sakin durulus.","ask":"Yumusak nefes.","kariyer":"Acele yok.","maddiDurum":"Olculu kal.","yakinDonem":"Sakin tempo.","sonuc":"Yavas ol.","semboller":[]}';
    const app = await testApp(
      testConfig(),
      async () =>
        new Response(
          JSON.stringify({
            choices: [
              {
                message: {
                  content: [{ type: 'text', text: json }],
                },
              },
            ],
          }),
          { status: 200, headers: { 'content-type': 'application/json' } },
        ),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: coffeeBody(),
    });
    expect(res.json().success).toBe(true);
    expect(res.json().data.overall).toContain('Sakin');
    await app.close();
  });
});
